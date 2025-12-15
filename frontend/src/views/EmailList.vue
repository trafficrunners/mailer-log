<template>
  <div>
    <!-- Filters -->
    <div class="bg-white rounded-lg shadow mb-6 p-4">
      <form @submit.prevent="applyFilters" class="space-y-4">
        <div class="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-6 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Recipient</label>
            <input
              v-model="filters.recipient"
              type="text"
              placeholder="Email address"
              class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
              @keydown="(e) => console.log('keydown', e.key)"
              @keyup.enter="applyFilters"
            >
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Sender</label>
            <input
              v-model="filters.sender"
              type="text"
              placeholder="From address"
              class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
              @keyup.enter="applyFilters"
            >
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Subject</label>
            <input
              v-model="filters.subject_search"
              type="text"
              placeholder="Subject contains..."
              class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
              @keyup.enter="applyFilters"
            >
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Mailer</label>
            <select
              v-model="filters.mailer"
              class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
            >
              <option value="">All</option>
              <option v-for="mailer in mailers" :key="mailer" :value="mailer">
                {{ mailer }}
              </option>
            </select>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Status</label>
            <select
              v-model="filters.status"
              class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
            >
              <option value="">All</option>
              <option v-for="status in statuses" :key="status" :value="status">
                {{ status }}
              </option>
            </select>
          </div>
          <div class="flex items-end">
            <button
              type="submit"
              class="w-full bg-blue-600 text-white rounded-md px-4 py-2 text-sm font-medium hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
            >
              Filter
            </button>
          </div>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-6 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Date From</label>
            <input
              v-model="filters.date_from"
              type="date"
              class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
            >
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Date To</label>
            <input
              v-model="filters.date_to"
              type="date"
              class="w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
            >
          </div>
          <div class="flex items-end">
            <button
              type="button"
              @click="clearFilters"
              class="text-blue-600 hover:text-blue-800 text-sm font-medium"
            >
              Clear
            </button>
          </div>
        </div>
      </form>
    </div>

    <!-- Results -->
    <div class="bg-white rounded-lg shadow">
      <div class="px-4 py-3 border-b border-gray-200">
        <h2 class="text-lg font-medium text-gray-900">
          Email Log ({{ totalCount }})
        </h2>
      </div>

      <div v-if="loading" class="p-8 text-center text-gray-500">
        Loading...
      </div>

      <div v-else-if="emails.length === 0" class="p-8 text-center text-gray-500">
        No emails found
      </div>

      <div v-else class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Sent At</th>
              <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Mailer</th>
              <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">To</th>
              <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Subject</th>
              <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr
              v-for="email in emails"
              :key="email.id"
              class="hover:bg-gray-50 cursor-pointer"
              @click="openEmail(email.id)"
            >
              <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-500">
                {{ formatDate(email.created_at) }}
              </td>
              <td class="px-4 py-3 text-sm">
                <code class="text-xs bg-gray-100 px-1 py-0.5 rounded">{{ email.mailer_class }}</code>
                <div v-if="email.mailer_action && email.mailer_action !== 'unknown'" class="text-xs text-gray-500 mt-0.5">
                  #{{ email.mailer_action }}
                </div>
              </td>
              <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-900">
                {{ email.to_addresses?.join(', ') }}
              </td>
              <td class="px-4 py-3 text-sm text-gray-900 max-w-md truncate">
                {{ email.subject || '(no subject)' }}
              </td>
              <td class="px-4 py-3 whitespace-nowrap">
                <StatusBadge :status="email.status" />
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Pagination -->
      <div v-if="totalPages > 1" class="px-4 py-3 border-t border-gray-200 flex items-center justify-between">
        <div class="text-sm text-gray-500">
          Page {{ currentPage }} of {{ totalPages }}
        </div>
        <div class="flex gap-2">
          <button
            @click="goToPage(currentPage - 1)"
            :disabled="currentPage === 1"
            class="px-3 py-1 text-sm border rounded-md disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50"
          >
            Previous
          </button>
          <button
            @click="goToPage(currentPage + 1)"
            :disabled="currentPage === totalPages"
            class="px-3 py-1 text-sm border rounded-md disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50"
          >
            Next
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { fetchEmails, fetchMailers } from '../api/emails'
import StatusBadge from '../components/StatusBadge.vue'

const route = useRoute()
const router = useRouter()

const loading = ref(true)
const emails = ref([])
const mailers = ref([])
const totalCount = ref(0)
const totalPages = ref(1)
const currentPage = ref(1)

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

function formatDate(dateString) {
  if (!dateString) return ''
  const date = new Date(dateString)
  return date.toLocaleString()
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
  console.log('applyFilters called', filters)
  currentPage.value = 1
  updateUrl()
  loadEmails()
}

function clearFilters() {
  Object.keys(filters).forEach(key => {
    filters[key] = ''
  })
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
  router.replace({ query })
}

function loadFromUrl() {
  Object.keys(filters).forEach(key => {
    if (route.query[key]) {
      filters[key] = route.query[key]
    }
  })
  if (route.query.page) {
    currentPage.value = parseInt(route.query.page, 10)
  }
}

function openEmail(id) {
  router.push({ name: 'email', params: { id } })
}

onMounted(() => {
  loadFromUrl()
  loadMailers()
  loadEmails()
})
</script>
