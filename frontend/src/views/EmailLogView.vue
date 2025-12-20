<template>
  <div class="flex flex-col h-[calc(100vh-80px)] gap-3">
    <!-- Filters -->
    <div class="bg-white rounded-lg shadow-sm flex-shrink-0">
      <button
        @click="showFilters = !showFilters"
        class="flex items-center gap-2 w-full px-4 py-3 text-sm font-medium text-gray-700 hover:bg-gray-50"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z"/>
        </svg>
        Filters
        <span v-if="activeFilterCount" class="bg-blue-500 text-white text-xs px-2 py-0.5 rounded-full">
          {{ activeFilterCount }}
        </span>
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

      <div v-show="showFilters" class="px-4 pb-4 border-t border-gray-200">
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 xl:grid-cols-7 gap-3 pt-3">
          <div>
            <label class="block text-xs font-medium text-gray-500 mb-1">Recipient</label>
            <input v-model="filters.recipient" type="text" placeholder="Email address"
              class="w-full px-2 py-1.5 text-sm border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-200 focus:border-blue-500 outline-none"
              @keyup.enter="applyFilters">
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-500 mb-1">Sender</label>
            <input v-model="filters.sender" type="text" placeholder="From address"
              class="w-full px-2 py-1.5 text-sm border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-200 focus:border-blue-500 outline-none"
              @keyup.enter="applyFilters">
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-500 mb-1">Subject</label>
            <input v-model="filters.subject_search" type="text" placeholder="Contains..."
              class="w-full px-2 py-1.5 text-sm border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-200 focus:border-blue-500 outline-none"
              @keyup.enter="applyFilters">
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-500 mb-1">Mailer</label>
            <select v-model="filters.mailer"
              class="w-full px-2 py-1.5 text-sm border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-200 focus:border-blue-500 outline-none"
              @change="applyFilters">
              <option value="">All</option>
              <option v-for="mailer in mailers" :key="mailer" :value="mailer">{{ mailer }}</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-500 mb-1">Status</label>
            <select v-model="filters.status"
              class="w-full px-2 py-1.5 text-sm border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-200 focus:border-blue-500 outline-none"
              @change="applyFilters">
              <option value="">All</option>
              <option v-for="status in statuses" :key="status" :value="status">{{ status }}</option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-500 mb-1">Date Range</label>
            <DateRangePicker
              v-model:date-from="filters.date_from"
              v-model:date-to="filters.date_to"
              @update:date-from="applyFilters"
              @update:date-to="applyFilters"
            />
          </div>
          <div class="flex items-end gap-2">
            <button @click="applyFilters" class="px-3 py-1.5 text-sm font-medium text-white bg-blue-500 rounded-md hover:bg-blue-600">
              Apply
            </button>
            <button @click="clearFilters" class="px-3 py-1.5 text-sm text-blue-500 hover:underline">
              Clear
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Main content -->
    <div class="flex-1 min-h-0 flex flex-col md:flex-row gap-3">
      <!-- Email list -->
      <div
        class="bg-white rounded-lg shadow-sm flex flex-col min-h-0"
        :class="selectedEmailId ? 'hidden md:flex md:w-[350px] lg:w-[450px] flex-shrink-0' : 'flex-1'"
      >
        <div class="px-4 py-3 border-b border-gray-200 flex-shrink-0 flex items-center justify-between">
          <h2 class="text-base font-semibold text-gray-900">
            Emails <span class="text-gray-400">({{ totalCount }})</span>
          </h2>
          <!-- Column visibility dropdown -->
          <div v-if="!isCompact" ref="columnMenuRef" class="relative">
            <button
              @click="showColumnMenu = !showColumnMenu"
              class="p-1.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded"
              title="Configure columns"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4"/>
              </svg>
            </button>
            <div
              v-if="showColumnMenu"
              class="absolute right-0 top-full mt-1 bg-white border border-gray-200 rounded-lg shadow-lg z-20 py-1 min-w-[160px]"
            >
              <div class="px-3 py-1.5 text-xs font-medium text-gray-500 uppercase border-b border-gray-100">
                Columns
              </div>
              <label
                v-for="col in columnConfig"
                :key="col.id"
                class="flex items-center gap-2 px-3 py-1.5 hover:bg-gray-50"
                :class="col.alwaysVisible ? 'cursor-not-allowed opacity-50' : 'cursor-pointer'"
              >
                <input
                  type="checkbox"
                  :checked="columnVisibility[col.id]"
                  :disabled="col.alwaysVisible"
                  @change="toggleColumn(col.id)"
                  class="rounded border-gray-300 text-blue-500 focus:ring-blue-500 disabled:opacity-50"
                >
                <span class="text-sm text-gray-700">{{ col.label }}</span>
              </label>
            </div>
          </div>
        </div>

        <div v-if="loading" class="p-8 text-center text-gray-500">Loading...</div>
        <div v-else-if="emails.length === 0" class="p-8 text-center text-gray-500">No emails found</div>

        <template v-else>
          <!-- Mobile: Card layout -->
          <div class="flex-1 overflow-auto md:hidden">
            <div class="divide-y divide-gray-100">
              <div
                v-for="email in emails"
                :key="email.id"
                @click="selectEmail(email.id)"
                class="p-4 hover:bg-gray-50 cursor-pointer"
                :class="{ 'bg-blue-50': email.id === selectedEmailId }"
              >
                <div class="flex items-start justify-between gap-2 mb-1">
                  <span class="text-sm font-medium text-gray-900 truncate">
                    {{ email.to_addresses?.join(', ') }}
                  </span>
                  <StatusBadge :status="email.status" />
                </div>
                <div class="text-sm text-gray-600 truncate mb-1">
                  {{ email.subject || '(no subject)' }}
                </div>
                <div class="flex items-center gap-2 text-xs text-gray-400">
                  <span>{{ formatDate(email.created_at) }}</span>
                  <span>·</span>
                  <code class="bg-gray-100 px-1 rounded">{{ email.mailer_class }}</code>
                </div>
              </div>
            </div>
          </div>

          <!-- Desktop: Table layout -->
          <div class="hidden md:block flex-1 overflow-auto">
          <table class="w-full text-[13px] table-fixed">
            <thead class="sticky top-0 bg-gray-50 z-10">
              <tr>
                <th
                  v-for="header in table.getHeaderGroups()[0].headers"
                  :key="header.id"
                  @click="header.column.getToggleSortingHandler()?.($event)"
                  class="px-2 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wide border-b border-gray-200 whitespace-nowrap first:pl-3 last:pr-3"
                  :class="[
                    header.column.columnDef.meta?.className,
                    {
                      'cursor-pointer select-none hover:bg-gray-100': header.column.getCanSort(),
                      'text-blue-500': header.column.getIsSorted()
                    }
                  ]"
                >
                  <div class="flex items-center gap-1">
                    <FlexRender :render="header.column.columnDef.header" :props="header.getContext()" />
                    <span v-if="header.column.getIsSorted()" class="text-xs">
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
                class="cursor-pointer border-b border-gray-100 hover:bg-gray-50 h-[52px]"
                :class="{ 'bg-blue-50': row.original.id === selectedEmailId }"
              >
                <td v-for="cell in row.getVisibleCells()" :key="cell.id" class="px-2 py-2 text-gray-700 first:pl-3 last:pr-3 align-middle" :class="cell.column.columnDef.meta?.className">
                  <FlexRender :render="cell.column.columnDef.cell" :props="cell.getContext()" />
                </td>
              </tr>
            </tbody>
          </table>
          </div>
        </template>

        <!-- Pagination -->
        <div v-if="totalPages > 1" class="flex items-center justify-between px-4 py-2 border-t border-gray-200 flex-shrink-0">
          <span class="text-xs text-gray-500">Page {{ currentPage }} of {{ totalPages }}</span>
          <div class="flex gap-1">
            <button
              @click="goToPage(currentPage - 1)"
              :disabled="currentPage === 1"
              class="px-2 py-1 text-sm border border-gray-300 rounded bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
            >←</button>
            <button
              @click="goToPage(currentPage + 1)"
              :disabled="currentPage === totalPages"
              class="px-2 py-1 text-sm border border-gray-300 rounded bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
            >→</button>
          </div>
        </div>
      </div>

      <!-- Email detail panel - fullscreen on mobile -->
      <Transition name="slide">
        <div
          v-if="selectedEmailId"
          class="fixed inset-0 z-50 bg-white md:relative md:inset-auto md:z-auto md:flex-1 md:min-w-0 md:rounded-lg md:shadow-sm flex flex-col"
        >
          <EmailDetailPanel :id="selectedEmailId" @close="selectedEmailId = null" />
        </div>
      </Transition>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted, h } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useLocalStorage, onClickOutside } from '@vueuse/core'
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
const showColumnMenu = ref(false)
const sorting = ref([{ id: 'created_at', desc: true }])

// Column visibility config
const columnConfig = [
  { id: 'status', label: 'Status', alwaysVisible: true },
  { id: 'created_at', label: 'Date' },
  { id: 'to', label: 'To' },
  { id: 'subject', label: 'Subject' },
  { id: 'mailer_class', label: 'Mailer' }
]

const defaultVisibility = {
  status: true,
  created_at: true,
  to: true,
  subject: true,
  mailer_class: true
}

const columnVisibility = useLocalStorage('mailer-log-column-visibility', defaultVisibility)

function toggleColumn(columnId) {
  const col = columnConfig.find(c => c.id === columnId)
  if (col?.alwaysVisible) return
  columnVisibility.value = {
    ...columnVisibility.value,
    [columnId]: !columnVisibility.value[columnId]
  }
}

// Close column menu when clicking outside
const columnMenuRef = ref(null)
onClickOutside(columnMenuRef, () => {
  showColumnMenu.value = false
})

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

const isCompact = computed(() => !!selectedEmailId.value)

// All column definitions
const allColumnDefs = computed(() => {
  const compact = isCompact.value
  return {
    status: columnHelper.accessor('status', {
      header: '',
      cell: info => h(StatusBadge, {
        status: info.getValue(),
        compact
      }),
      meta: { className: compact ? 'w-[32px]' : 'w-[90px]' },
      enableSorting: true
    }),
    created_at: columnHelper.accessor('created_at', {
      header: 'Date',
      cell: info => h('span', { class: 'whitespace-nowrap' }, formatDate(info.getValue())),
      meta: { className: 'w-[120px]' }
    }),
    to: columnHelper.accessor(row => row.to_addresses?.join(', '), {
      id: 'to',
      header: 'To',
      cell: info => h('span', { class: 'block truncate', title: info.getValue() }, info.getValue()),
      meta: { className: 'w-[180px] max-w-[180px]' }
    }),
    subject: columnHelper.accessor('subject', {
      header: 'Subject',
      cell: info => h('span', { class: 'block truncate' }, info.getValue() || '(no subject)')
    }),
    mailer_class: columnHelper.accessor('mailer_class', {
      header: 'Mailer',
      cell: info => {
        const row = info.row.original
        const mailer = info.getValue()
        const action = row.mailer_action && row.mailer_action !== 'unknown' ? `#${row.mailer_action}` : ''
        return h('div', { class: 'flex flex-col gap-0.5 items-start' }, [
          h('code', { class: 'text-xs bg-gray-100 px-1 rounded inline-block' }, mailer),
          action ? h('span', { class: 'text-[11px] text-gray-500' }, action) : null
        ])
      },
      meta: { className: 'w-[180px]' }
    })
  }
})

// In compact mode show only first 3 visible columns
const columns = computed(() => {
  const compact = isCompact.value
  const defs = allColumnDefs.value
  const visibility = columnVisibility.value

  // Filter columns based on visibility settings
  const visibleCols = columnConfig
    .filter(col => visibility[col.id])
    .map(col => defs[col.id])

  // In compact mode, show only first 3 columns
  return compact ? visibleCols.slice(0, 3) : visibleCols
})

const table = useVueTable({
  get data() { return emails.value },
  get columns() { return columns.value },
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
    const params = {
      page: currentPage.value,
      ...Object.fromEntries(
        Object.entries(filters).filter(([_, v]) => v)
      )
    }
    const data = await fetchEmails(params)
    emails.value = data.emails
    totalCount.value = data.total_count
    totalPages.value = data.total_pages
  } catch (e) {
    console.error('Failed to load emails:', e)
  } finally {
    loading.value = false
  }
}

async function loadMailers() {
  try {
    const data = await fetchMailers()
    mailers.value = data.mailers
  } catch (e) {
    console.error('Failed to load mailers:', e)
  }
}

function applyFilters() {
  currentPage.value = 1
  loadEmails()
  updateUrl()
}

function clearFilters() {
  Object.keys(filters).forEach(key => filters[key] = '')
  applyFilters()
}

function goToPage(page) {
  currentPage.value = page
  loadEmails()
  updateUrl()
}

function updateUrl() {
  const query = {}
  if (currentPage.value > 1) query.page = currentPage.value
  Object.entries(filters).forEach(([k, v]) => { if (v) query[k] = v })
  if (selectedEmailId.value) query.email = selectedEmailId.value
  router.replace({ query })
}

function loadFromUrl() {
  if (route.query.page) currentPage.value = parseInt(route.query.page, 10)
  Object.keys(filters).forEach(key => {
    if (route.query[key]) filters[key] = route.query[key]
  })
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
/* Slide transition for detail panel */
.slide-enter-active {
  transition: opacity 0.15s ease, transform 0.15s ease;
}
.slide-leave-active {
  transition: opacity 0.1s ease, transform 0.1s ease;
}
.slide-enter-from {
  opacity: 0;
  transform: translateX(100%);
}
.slide-leave-to {
  opacity: 0;
  transform: translateX(100%);
}
@media (min-width: 768px) {
  .slide-enter-from,
  .slide-leave-to {
    transform: translateX(20px);
  }
}
</style>
