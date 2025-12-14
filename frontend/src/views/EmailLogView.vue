<template>
  <div class="email-log-container">
    <!-- Filters - collapsible on top -->
    <div class="filters-section">
      <button
        @click="showFilters = !showFilters"
        class="filters-toggle"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z"/>
        </svg>
        Filters
        <span v-if="activeFilterCount" class="filter-count">{{ activeFilterCount }}</span>
        <svg
          class="w-4 h-4 ml-auto transition-transform"
          :class="{ 'rotate-180': showFilters }"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
        </svg>
      </button>

      <div v-show="showFilters" class="filters-panel">
        <div class="filters-grid">
          <div>
            <label class="filter-label">Recipient</label>
            <input v-model="filters.recipient" type="email" placeholder="Email address" class="filter-input">
          </div>
          <div>
            <label class="filter-label">Sender</label>
            <input v-model="filters.sender" type="text" placeholder="From address" class="filter-input">
          </div>
          <div>
            <label class="filter-label">Subject</label>
            <input v-model="filters.subject_search" type="text" placeholder="Contains..." class="filter-input">
          </div>
          <div>
            <label class="filter-label">Mailer</label>
            <select v-model="filters.mailer" class="filter-input">
              <option value="">All</option>
              <option v-for="mailer in mailers" :key="mailer" :value="mailer">{{ mailer }}</option>
            </select>
          </div>
          <div>
            <label class="filter-label">Status</label>
            <select v-model="filters.status" class="filter-input">
              <option value="">All</option>
              <option v-for="status in statuses" :key="status" :value="status">{{ status }}</option>
            </select>
          </div>
          <div class="date-filter-cell">
            <label class="filter-label">Date Range</label>
            <DateRangePicker
              v-model:date-from="filters.date_from"
              v-model:date-to="filters.date_to"
            />
          </div>
          <div class="filter-actions">
            <button @click="applyFilters" class="btn-primary">Apply</button>
            <button @click="clearFilters" class="btn-secondary">Clear</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Main content: split view -->
    <div class="split-container">
      <!-- Left: Email list -->
      <div class="email-list-panel" :class="{ 'has-selection': selectedEmailId }">
        <div class="list-header">
          <h2 class="list-title">Emails <span class="text-gray-400">({{ totalCount }})</span></h2>
        </div>

        <div v-if="loading" class="loading-state">Loading...</div>
        <div v-else-if="emails.length === 0" class="empty-state">No emails found</div>

        <div v-else class="table-wrapper">
          <table class="email-table">
            <thead>
              <tr>
                <th
                  v-for="header in table.getHeaderGroups()[0].headers"
                  :key="header.id"
                  @click="header.column.getToggleSortingHandler()?.($event)"
                  :class="{ 'sortable': header.column.getCanSort(), 'sorted': header.column.getIsSorted() }"
                >
                  <div class="th-content">
                    <FlexRender
                      :render="header.column.columnDef.header"
                      :props="header.getContext()"
                    />
                    <span v-if="header.column.getIsSorted()" class="sort-indicator">
                      {{ header.column.getIsSorted() === 'asc' ? '↑' : '↓' }}
                    </span>
                  </div>
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="row in table.getRowModel().rows"
                :key="row.id"
                @click="selectEmail(row.original.id)"
                :class="{ 'selected': row.original.id === selectedEmailId }"
              >
                <td v-for="cell in row.getVisibleCells()" :key="cell.id">
                  <FlexRender
                    :render="cell.column.columnDef.cell"
                    :props="cell.getContext()"
                  />
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Pagination -->
        <div v-if="totalPages > 1" class="pagination">
          <span class="page-info">Page {{ currentPage }} of {{ totalPages }}</span>
          <div class="page-buttons">
            <button @click="goToPage(currentPage - 1)" :disabled="currentPage === 1" class="page-btn">←</button>
            <button @click="goToPage(currentPage + 1)" :disabled="currentPage === totalPages" class="page-btn">→</button>
          </div>
        </div>
      </div>

      <!-- Right: Email detail -->
      <Transition name="slide">
        <div v-if="selectedEmailId" class="email-detail-panel">
          <EmailDetailPanel :id="selectedEmailId" @close="selectedEmailId = null" />
        </div>
      </Transition>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, watch, h } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useLocalStorage } from '@vueuse/core'
import {
  useVueTable,
  createColumnHelper,
  getCoreRowModel,
  getSortedRowModel,
  FlexRender
} from '@tanstack/vue-table'
import { fetchEmails, fetchMailers } from '../api/emails'
import StatusBadge from '../components/StatusBadge.vue'
import EmailDetailPanel from '../components/EmailDetailPanel.vue'
import DateRangePicker from '../components/DateRangePicker.vue'

const route = useRoute()
const router = useRouter()

const loading = ref(true)
const emails = ref([])
const mailers = ref([])
const totalCount = ref(0)
const totalPages = ref(1)
const currentPage = ref(1)
const selectedEmailId = ref(null)
const showFilters = useLocalStorage('mailer-log-filters-visible', true)
const sorting = ref([{ id: 'created_at', desc: true }])

const statuses = ['pending', 'sent', 'delivered', 'opened', 'clicked', 'bounced', 'complained']

const filters = reactive({
  recipient: '',
  sender: '',
  subject_search: '',
  mailer: '',
  status: '',
  date_from: '',
  date_to: ''
})

const activeFilterCount = computed(() => {
  return Object.values(filters).filter(v => v).length
})

const columnHelper = createColumnHelper()

const columns = [
  columnHelper.accessor('created_at', {
    header: 'Date',
    cell: info => formatDate(info.getValue()),
    size: 140
  }),
  columnHelper.accessor('mailer_class', {
    header: 'Mailer',
    cell: info => {
      const row = info.row.original
      const mailer = info.getValue()
      const action = row.mailer_action && row.mailer_action !== 'unknown' ? `#${row.mailer_action}` : ''
      return h('div', { class: 'mailer-cell' }, [
        h('code', { class: 'mailer-name' }, mailer),
        action ? h('span', { class: 'mailer-action' }, action) : null
      ])
    },
    size: 180
  }),
  columnHelper.accessor(row => row.to_addresses?.join(', '), {
    id: 'to',
    header: 'To',
    size: 200
  }),
  columnHelper.accessor('subject', {
    header: 'Subject',
    cell: info => info.getValue() || '(no subject)'
  }),
  columnHelper.accessor('status', {
    header: 'Status',
    cell: info => h(StatusBadge, { status: info.getValue() }),
    size: 100
  })
]

const table = useVueTable({
  get data() { return emails.value },
  columns,
  state: {
    get sorting() { return sorting.value }
  },
  onSortingChange: updaterOrValue => {
    sorting.value = typeof updaterOrValue === 'function'
      ? updaterOrValue(sorting.value)
      : updaterOrValue
  },
  getCoreRowModel: getCoreRowModel(),
  getSortedRowModel: getSortedRowModel(),
  manualSorting: false
})

function formatDate(dateString) {
  if (!dateString) return ''
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

async function loadEmails() {
  loading.value = true
  try {
    const params = { ...filters, page: currentPage.value }
    const data = await fetchEmails(params)
    emails.value = data.emails
    totalCount.value = data.total_count
    totalPages.value = data.total_pages
    currentPage.value = data.current_page
  } catch (error) {
    console.error('Failed to load emails:', error)
  } finally {
    loading.value = false
  }
}

async function loadMailers() {
  try {
    const data = await fetchMailers()
    mailers.value = data.mailers
  } catch (error) {
    console.error('Failed to load mailers:', error)
  }
}

function applyFilters() {
  currentPage.value = 1
  updateUrl()
  loadEmails()
}

function clearFilters() {
  Object.keys(filters).forEach(key => { filters[key] = '' })
  currentPage.value = 1
  updateUrl()
  loadEmails()
}

function goToPage(page) {
  if (page < 1 || page > totalPages.value) return
  currentPage.value = page
  updateUrl()
  loadEmails()
}

function updateUrl() {
  const query = {}
  Object.entries(filters).forEach(([key, value]) => {
    if (value) query[key] = value
  })
  if (currentPage.value > 1) query.page = currentPage.value
  if (selectedEmailId.value) query.email = selectedEmailId.value
  router.replace({ query })
}

function loadFromUrl() {
  Object.keys(filters).forEach(key => {
    if (route.query[key]) filters[key] = route.query[key]
  })
  if (route.query.page) currentPage.value = parseInt(route.query.page, 10)
  if (route.query.email) selectedEmailId.value = parseInt(route.query.email, 10)
}

function selectEmail(id) {
  selectedEmailId.value = id
  updateUrl()
}

onMounted(() => {
  loadFromUrl()
  loadMailers()
  loadEmails()
})
</script>

<style scoped>
.email-log-container {
  display: flex;
  flex-direction: column;
  height: calc(100vh - 80px);
  gap: 0.75rem;
}

/* Filters */
.filters-section {
  background: white;
  border-radius: 0.5rem;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  flex-shrink: 0;
}

.filters-toggle {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  width: 100%;
  padding: 0.75rem 1rem;
  font-weight: 500;
  font-size: 0.875rem;
  color: #374151;
  background: none;
  border: none;
  cursor: pointer;
}

.filters-toggle:hover {
  background: #f9fafb;
}

.filter-count {
  background: #3b82f6;
  color: white;
  font-size: 0.75rem;
  padding: 0.125rem 0.5rem;
  border-radius: 9999px;
}

.filters-panel {
  padding: 0 1rem 1rem;
  border-top: 1px solid #e5e7eb;
}

.filters-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  padding-top: 0.75rem;
}

.filters-grid > div {
  flex: 1;
  min-width: 120px;
}

.filters-grid > .date-filter-cell {
  flex: 1.5;
  min-width: 180px;
}

.filter-label {
  display: block;
  font-size: 0.75rem;
  font-weight: 500;
  color: #6b7280;
  margin-bottom: 0.25rem;
}

.filter-input {
  width: 100%;
  padding: 0.375rem 0.5rem;
  font-size: 0.875rem;
  border: 1px solid #d1d5db;
  border-radius: 0.375rem;
}

.filter-input:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.2);
}

.filter-actions {
  display: flex;
  align-items: flex-end;
  gap: 0.5rem;
}

.btn-primary {
  padding: 0.375rem 0.75rem;
  font-size: 0.875rem;
  font-weight: 500;
  color: white;
  background: #3b82f6;
  border: none;
  border-radius: 0.375rem;
  cursor: pointer;
}

.btn-primary:hover {
  background: #2563eb;
}

.btn-secondary {
  padding: 0.375rem 0.75rem;
  font-size: 0.875rem;
  color: #3b82f6;
  background: none;
  border: none;
  cursor: pointer;
}

.btn-secondary:hover {
  text-decoration: underline;
}

/* Split container */
.split-container {
  display: flex;
  flex: 1;
  gap: 0.75rem;
  min-height: 0;
}

/* Email list panel */
.email-list-panel {
  display: flex;
  flex-direction: column;
  background: white;
  border-radius: 0.5rem;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  flex: 1;
  min-width: 0;
}

.email-list-panel.has-selection {
  flex: 0 0 30%;
  max-width: 450px;
  min-width: 300px;
}

.list-header {
  padding: 0.75rem 1rem;
  border-bottom: 1px solid #e5e7eb;
  flex-shrink: 0;
}

.list-title {
  font-size: 1rem;
  font-weight: 600;
  color: #111827;
  margin: 0;
}

.loading-state,
.empty-state {
  padding: 2rem;
  text-align: center;
  color: #6b7280;
}

.table-wrapper {
  flex: 1;
  overflow: auto;
}

/* Table styles */
.email-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.8125rem;
}

.email-table thead {
  position: sticky;
  top: 0;
  background: #f9fafb;
  z-index: 1;
}

.email-table th {
  padding: 0.5rem 0.75rem;
  text-align: left;
  font-weight: 500;
  color: #6b7280;
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.025em;
  border-bottom: 1px solid #e5e7eb;
  white-space: nowrap;
}

.email-table th.sortable {
  cursor: pointer;
  user-select: none;
}

.email-table th.sortable:hover {
  background: #f3f4f6;
}

.email-table th.sorted {
  color: #3b82f6;
}

.th-content {
  display: flex;
  align-items: center;
  gap: 0.25rem;
}

.sort-indicator {
  font-size: 0.75rem;
}

.email-table tbody tr {
  cursor: pointer;
  border-bottom: 1px solid #f3f4f6;
}

.email-table tbody tr:hover {
  background: #f9fafb;
}

.email-table tbody tr.selected {
  background: #eff6ff;
}

.email-table td {
  padding: 0.5rem 0.75rem;
  color: #374151;
  max-width: 200px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.mailer-cell {
  display: flex;
  flex-direction: column;
  gap: 0.125rem;
}

.mailer-name {
  font-size: 0.75rem;
  background: #f3f4f6;
  padding: 0.125rem 0.25rem;
  border-radius: 0.25rem;
}

.mailer-action {
  font-size: 0.6875rem;
  color: #6b7280;
}

/* Pagination */
.pagination {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.5rem 1rem;
  border-top: 1px solid #e5e7eb;
  flex-shrink: 0;
}

.page-info {
  font-size: 0.75rem;
  color: #6b7280;
}

.page-buttons {
  display: flex;
  gap: 0.25rem;
}

.page-btn {
  padding: 0.25rem 0.5rem;
  font-size: 0.875rem;
  border: 1px solid #d1d5db;
  border-radius: 0.25rem;
  background: white;
  cursor: pointer;
}

.page-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.page-btn:not(:disabled):hover {
  background: #f3f4f6;
}

/* Email detail panel */
.email-detail-panel {
  flex: 1;
  min-width: 0;
  background: white;
  border-radius: 0.5rem;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

/* Slide transition */
.slide-enter-active {
  transition: opacity 0.15s ease, transform 0.15s ease;
}

.slide-leave-active {
  transition: opacity 0.1s ease, transform 0.1s ease;
}

.slide-enter-from {
  opacity: 0;
  transform: translateX(20px);
}

.slide-leave-to {
  opacity: 0;
  transform: translateX(20px);
}

/* Responsive */
@media (max-width: 1024px) {
  .split-container {
    flex-direction: column;
  }

  .email-list-panel.has-selection {
    flex: 0 0 40%;
    max-width: none;
    min-width: 0;
  }

  .email-detail-panel {
    flex: 1;
  }

  .slide-enter-from,
  .slide-leave-to {
    transform: translateY(20px);
  }
}
</style>
