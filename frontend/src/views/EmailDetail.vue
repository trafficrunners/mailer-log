<template>
  <div>
    <div class="mb-4">
      <router-link
        to="/"
        class="inline-flex items-center text-sm text-gray-500 hover:text-gray-700"
      >
        <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/>
        </svg>
        Back to Email Log
      </router-link>
    </div>

    <div v-if="loading" class="bg-white rounded-lg shadow p-8 text-center text-gray-500">
      Loading...
    </div>

    <div v-else-if="error" class="bg-white rounded-lg shadow p-8 text-center text-red-500">
      {{ error }}
    </div>

    <div v-else-if="email" class="space-y-6">
      <!-- Header -->
      <div class="bg-white rounded-lg shadow">
        <div class="px-4 py-3 border-b border-gray-200 flex items-center justify-between">
          <h2 class="text-lg font-medium text-gray-900">
            {{ email.subject || '(no subject)' }}
          </h2>
          <StatusBadge :status="email.status" />
        </div>

        <div class="p-4 grid grid-cols-1 md:grid-cols-2 gap-6">
          <div class="space-y-3">
            <div class="flex">
              <span class="w-24 text-sm text-gray-500">From</span>
              <code class="text-sm">{{ email.from_address }}</code>
            </div>
            <div class="flex">
              <span class="w-24 text-sm text-gray-500">To</span>
              <code class="text-sm">{{ email.to_addresses?.join(', ') }}</code>
            </div>
            <div v-if="email.cc_addresses?.length" class="flex">
              <span class="w-24 text-sm text-gray-500">CC</span>
              <code class="text-sm">{{ email.cc_addresses.join(', ') }}</code>
            </div>
            <div v-if="email.bcc_addresses?.length" class="flex">
              <span class="w-24 text-sm text-gray-500">BCC</span>
              <code class="text-sm">{{ email.bcc_addresses.join(', ') }}</code>
            </div>
            <div class="flex">
              <span class="w-24 text-sm text-gray-500">Mailer</span>
              <code class="text-sm">{{ email.mailer_class }}#{{ email.mailer_action }}</code>
            </div>
            <div class="flex">
              <span class="w-24 text-sm text-gray-500">Message ID</span>
              <code class="text-xs text-gray-600 break-all">{{ email.message_id }}</code>
            </div>
          </div>

          <div class="space-y-3">
            <div class="flex">
              <span class="w-24 text-sm text-gray-500">Sent At</span>
              <span class="text-sm">{{ formatDate(email.created_at) }}</span>
            </div>
            <div v-if="email.delivered_at" class="flex">
              <span class="w-24 text-sm text-gray-500">Delivered</span>
              <span class="text-sm">{{ formatDate(email.delivered_at) }}</span>
            </div>
            <div v-if="email.opened_at" class="flex">
              <span class="w-24 text-sm text-gray-500">Opened</span>
              <span class="text-sm">{{ formatDate(email.opened_at) }}</span>
            </div>
            <div v-if="email.clicked_at" class="flex">
              <span class="w-24 text-sm text-gray-500">Clicked</span>
              <span class="text-sm">{{ formatDate(email.clicked_at) }}</span>
            </div>
            <div v-if="email.domain" class="flex">
              <span class="w-24 text-sm text-gray-500">Domain</span>
              <code class="text-sm">{{ email.domain }}</code>
            </div>
          </div>
        </div>
      </div>

      <!-- Events -->
      <div v-if="email.events?.length" class="bg-white rounded-lg shadow">
        <div class="px-4 py-3 border-b border-gray-200">
          <h3 class="text-md font-medium text-gray-900">Delivery Events</h3>
        </div>
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Event</th>
                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Time</th>
                <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Recipient</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
              <tr v-for="event in email.events" :key="event.id">
                <td class="px-4 py-2">
                  <StatusBadge :status="event.event_type" />
                </td>
                <td class="px-4 py-2 text-sm text-gray-500">
                  {{ formatTime(event.occurred_at) }}
                </td>
                <td class="px-4 py-2 text-sm text-gray-500">
                  {{ event.recipient }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Email Preview -->
      <div class="bg-white rounded-lg shadow">
        <div class="px-4 py-3 border-b border-gray-200">
          <h3 class="text-md font-medium text-gray-900">Email Preview</h3>
        </div>
        <div class="p-4">
          <div v-if="email.html_body" class="border rounded-md bg-white">
            <iframe
              :srcdoc="email.html_body"
              class="w-full h-96 border-0"
              sandbox="allow-same-origin"
            />
          </div>
          <pre v-else-if="email.text_body" class="bg-gray-50 p-4 rounded-md text-sm overflow-auto max-h-96">{{ email.text_body }}</pre>
          <p v-else class="text-gray-500 text-sm">No email body available.</p>
        </div>
      </div>

      <!-- Call Stack -->
      <details v-if="email.call_stack?.length" class="bg-white rounded-lg shadow">
        <summary class="px-4 py-3 cursor-pointer text-md font-medium text-gray-900 hover:bg-gray-50">
          Call Stack
        </summary>
        <div class="px-4 pb-4">
          <pre class="bg-gray-50 p-4 rounded-md text-xs overflow-auto max-h-64">{{ email.call_stack?.join('\n') }}</pre>
        </div>
      </details>

      <!-- Headers -->
      <details v-if="email.headers && Object.keys(email.headers).length" class="bg-white rounded-lg shadow">
        <summary class="px-4 py-3 cursor-pointer text-md font-medium text-gray-900 hover:bg-gray-50">
          Headers
        </summary>
        <div class="px-4 pb-4">
          <pre class="bg-gray-50 p-4 rounded-md text-xs overflow-auto max-h-64">{{ JSON.stringify(email.headers, null, 2) }}</pre>
        </div>
      </details>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { fetchEmail } from '../api/emails'
import StatusBadge from '../components/StatusBadge.vue'

const props = defineProps({
  id: {
    type: [String, Number],
    required: true
  }
})

const loading = ref(true)
const error = ref(null)
const email = ref(null)

function formatDate(dateString) {
  if (!dateString) return ''
  const date = new Date(dateString)
  return date.toLocaleString()
}

function formatTime(dateString) {
  if (!dateString) return ''
  const date = new Date(dateString)
  return date.toLocaleTimeString()
}

async function loadEmail() {
  loading.value = true
  error.value = null
  try {
    const data = await fetchEmail(props.id)
    email.value = data.email
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadEmail()
})
</script>
