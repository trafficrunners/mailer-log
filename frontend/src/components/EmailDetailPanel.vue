<template>
  <div class="flex flex-col h-full bg-white">
    <!-- Header -->
    <div class="flex items-center gap-2 px-4 py-3 border-b border-gray-200 flex-shrink-0">
      <button
        @click="$emit('close')"
        class="p-1.5 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded"
        title="Close"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
        </svg>
      </button>
      <div class="flex items-center gap-3 min-w-0 flex-1">
        <StatusBadge :status="email?.status" />
        <h2 class="text-[15px] font-semibold text-gray-900 truncate">
          {{ email?.subject || '(no subject)' }}
        </h2>
      </div>
    </div>

    <div v-if="loading" class="p-8 text-center text-gray-500">Loading...</div>
    <div v-else-if="error" class="p-8 text-center text-red-600">{{ error }}</div>

    <div v-else-if="email" class="flex flex-col flex-1 min-h-0 overflow-hidden">
      <!-- Meta info (expandable) -->
      <div class="border-b border-gray-200 flex-shrink-0">
        <div
          class="px-4 py-3 cursor-pointer hover:bg-gray-50 transition-colors"
          @click="showHeaders = !showHeaders"
        >
          <div class="flex flex-col gap-3 md:flex-row md:justify-between md:gap-4">
            <!-- From/To addresses -->
            <div class="flex flex-col gap-1.5 min-w-0 flex-1">
              <div class="flex items-baseline gap-2 text-[13px]">
                <span class="text-gray-500 flex-shrink-0 min-w-[32px]">From</span>
                <code
                  class="text-gray-900 text-xs bg-gray-100 px-1.5 py-0.5 rounded truncate max-w-full"
                  :title="email.from_address"
                >{{ email.from_address }}</code>
              </div>
              <div class="flex items-baseline gap-2 text-[13px]">
                <span class="text-gray-500 flex-shrink-0 min-w-[32px]">To</span>
                <code
                  class="text-gray-900 text-xs bg-gray-100 px-1.5 py-0.5 rounded truncate max-w-full"
                  :title="email.to_addresses?.join(', ')"
                >{{ email.to_addresses?.join(', ') }}</code>
              </div>
              <div v-if="email.cc_addresses?.length" class="flex items-baseline gap-2 text-[13px]">
                <span class="text-gray-500 flex-shrink-0 min-w-[32px]">CC</span>
                <code
                  class="text-gray-900 text-xs bg-gray-100 px-1.5 py-0.5 rounded truncate max-w-full"
                  :title="email.cc_addresses.join(', ')"
                >{{ email.cc_addresses.join(', ') }}</code>
              </div>
            </div>

            <!-- Date & Mailer + expand icon -->
            <div class="flex items-start gap-3">
              <div class="flex flex-row gap-4 md:flex-col md:gap-1.5 flex-shrink-0 md:text-right text-[13px]">
                <div class="flex items-baseline gap-2 md:justify-end">
                  <span class="text-gray-500">Sent</span>
                  <span class="text-gray-900">{{ formatDate(email.created_at) }}</span>
                </div>
                <div class="flex items-baseline gap-2 md:justify-end">
                  <span class="text-gray-500">Mailer</span>
                  <code class="text-gray-900 text-xs bg-gray-100 px-1.5 py-0.5 rounded">
                    {{ email.mailer_class }}#{{ email.mailer_action }}
                  </code>
                </div>
              </div>
              <svg
                class="w-4 h-4 text-gray-400 flex-shrink-0 transition-transform duration-200 mt-0.5"
                :class="{ 'rotate-180': showHeaders }"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
              </svg>
            </div>
          </div>
        </div>

        <!-- Headers (expanded) -->
        <div v-if="showHeaders && filteredHeaders.length" class="px-4 pb-3 pt-1 border-t border-gray-100 bg-gray-50">
          <div class="flex flex-col gap-1">
            <div v-for="[key, value] in filteredHeaders" :key="key" class="flex gap-2 text-xs">
              <span class="text-gray-500 flex-shrink-0 min-w-[100px] sm:min-w-[140px] font-mono">{{ key }}</span>
              <span class="text-gray-900 break-all font-mono">{{ formatHeaderValue(value) }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Tabs -->
      <div class="flex flex-col flex-1 min-h-0">
        <div class="flex gap-1 px-4 pt-2 border-b border-gray-200 flex-shrink-0 overflow-x-auto">
          <button
            v-for="tab in availableTabs"
            :key="tab.id"
            @click="activeTab = tab.id"
            class="flex items-center gap-1.5 px-3 py-2 text-[13px] font-medium border-b-2 -mb-px whitespace-nowrap"
            :class="activeTab === tab.id
              ? 'text-blue-500 border-blue-500'
              : 'text-gray-500 border-transparent hover:text-gray-700'"
          >
            {{ tab.label }}
            <span
              v-if="tab.count"
              class="text-[11px] px-1.5 py-0.5 rounded-full"
              :class="activeTab === tab.id ? 'bg-blue-100 text-blue-500' : 'bg-gray-200 text-gray-600'"
            >
              {{ tab.count }}
            </span>
          </button>
        </div>

        <div class="flex-1 overflow-auto">
          <!-- Preview tab -->
          <div v-if="activeTab === 'preview'" class="h-full">
            <div v-if="email.html_body" class="h-full relative">
              <div v-if="iframeLoading" class="absolute inset-0 flex items-center justify-center bg-gray-50 text-gray-500 text-sm">
                Loading preview...
              </div>
              <iframe
                :srcdoc="email.html_body"
                sandbox="allow-same-origin"
                class="w-full h-full border-none transition-opacity duration-150"
                :class="{ 'opacity-0': iframeLoading }"
                @load="iframeLoading = false"
              />
            </div>
            <pre v-else-if="email.text_body" class="m-0 p-4 text-[13px] bg-gray-50 overflow-auto h-full">{{ email.text_body }}</pre>
            <p v-else class="p-8 text-center text-gray-500 text-sm">No email body available</p>
          </div>

          <!-- Events tab -->
          <div v-else-if="activeTab === 'events'" class="h-full">
            <div v-if="email.events?.length" class="p-2">
              <div
                v-for="event in email.events"
                :key="event.id"
                class="mb-1"
              >
                <div
                  class="flex items-center gap-2 sm:gap-3 p-2.5 rounded-md cursor-pointer border border-transparent transition-all"
                  :class="expandedEvents.has(event.id)
                    ? 'bg-gray-100 border-gray-200 rounded-b-none'
                    : 'hover:bg-gray-50'"
                  @click="toggleEvent(event.id)"
                >
                  <StatusBadge :status="event.event_type" class="flex-shrink-0" />
                  <span class="text-xs text-gray-500 whitespace-nowrap flex-shrink-0 hidden sm:inline">{{ formatDateTime(event.occurred_at) }}</span>
                  <span class="text-[13px] text-gray-700 truncate flex-1 min-w-0">{{ event.recipient }}</span>
                  <span v-if="event.city || event.country" class="hidden sm:inline text-[11px] text-gray-400 bg-gray-100 px-2 py-0.5 rounded-full flex-shrink-0">
                    {{ [event.city, event.country].filter(Boolean).join(', ') }}
                  </span>
                  <span v-if="event.device_type" class="hidden sm:inline text-[11px] text-gray-400 bg-gray-100 px-2 py-0.5 rounded-full flex-shrink-0">
                    {{ event.device_type }}
                  </span>
                  <svg
                    class="w-4 h-4 text-gray-400 flex-shrink-0 transition-transform duration-200"
                    :class="{ 'rotate-180': expandedEvents.has(event.id) }"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
                  </svg>
                </div>

                <!-- Event Details -->
                <div
                  v-if="expandedEvents.has(event.id)"
                  class="bg-gray-50 border border-gray-200 border-t-0 rounded-b-md p-3 mb-2"
                >
                  <div v-if="hasEventDetails(event)" class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <!-- Client Info -->
                    <div v-if="event.user_agent || event.client_name" class="min-w-0">
                      <h4 class="text-[11px] font-semibold text-gray-500 uppercase tracking-wide mb-2">Client Info</h4>
                      <div class="flex flex-col gap-1.5">
                        <div v-if="event.client_name" class="flex gap-2 text-xs">
                          <span class="text-gray-500 flex-shrink-0 min-w-[70px]">Client</span>
                          <span class="text-gray-900 break-words">{{ event.client_name }}</span>
                        </div>
                        <div v-if="event.client_os" class="flex gap-2 text-xs">
                          <span class="text-gray-500 flex-shrink-0 min-w-[70px]">OS</span>
                          <span class="text-gray-900 break-words">{{ event.client_os }}</span>
                        </div>
                        <div v-if="event.device_type" class="flex gap-2 text-xs">
                          <span class="text-gray-500 flex-shrink-0 min-w-[70px]">Device</span>
                          <span class="text-gray-900 break-words">{{ event.device_type }}</span>
                        </div>
                        <div v-if="event.user_agent" class="flex gap-2 text-xs">
                          <span class="text-gray-500 flex-shrink-0 min-w-[70px]">User Agent</span>
                          <span class="text-gray-900 break-all">{{ event.user_agent }}</span>
                        </div>
                      </div>
                    </div>

                    <!-- Location -->
                    <div v-if="event.ip_address || event.country" class="min-w-0">
                      <h4 class="text-[11px] font-semibold text-gray-500 uppercase tracking-wide mb-2">Location</h4>
                      <div class="flex flex-col gap-1.5">
                        <div v-if="event.ip_address" class="flex gap-2 text-xs">
                          <span class="text-gray-500 flex-shrink-0 min-w-[70px]">IP Address</span>
                          <code class="text-gray-900 bg-gray-200 px-1 py-0.5 rounded text-[11px]">{{ event.ip_address }}</code>
                        </div>
                        <div v-if="event.country" class="flex gap-2 text-xs">
                          <span class="text-gray-500 flex-shrink-0 min-w-[70px]">Country</span>
                          <span class="text-gray-900 break-words">{{ event.country }}</span>
                        </div>
                        <div v-if="event.region" class="flex gap-2 text-xs">
                          <span class="text-gray-500 flex-shrink-0 min-w-[70px]">Region</span>
                          <span class="text-gray-900 break-words">{{ event.region }}</span>
                        </div>
                        <div v-if="event.city" class="flex gap-2 text-xs">
                          <span class="text-gray-500 flex-shrink-0 min-w-[70px]">City</span>
                          <span class="text-gray-900 break-words">{{ event.city }}</span>
                        </div>
                      </div>
                    </div>

                    <!-- URL (for clicks) -->
                    <div v-if="event.url" class="sm:col-span-2 min-w-0">
                      <h4 class="text-[11px] font-semibold text-gray-500 uppercase tracking-wide mb-2">Clicked URL</h4>
                      <a
                        :href="event.url"
                        target="_blank"
                        class="block text-xs text-blue-500 break-all no-underline px-2 py-1.5 bg-blue-50 rounded border border-blue-100 hover:underline hover:bg-blue-100"
                      >{{ event.url }}</a>
                    </div>

                    <!-- Delivery Status (for delivered/bounced) -->
                    <div v-if="event.raw_payload?.delivery_status" class="sm:col-span-2 min-w-0">
                      <h4 class="text-[11px] font-semibold text-gray-500 uppercase tracking-wide mb-2">Delivery Status</h4>
                      <div class="flex flex-col gap-1.5">
                        <div v-if="event.raw_payload.delivery_status.code" class="flex gap-2 text-xs">
                          <span class="text-gray-500 flex-shrink-0 min-w-[70px]">Code</span>
                          <code class="text-gray-900 bg-gray-200 px-1 py-0.5 rounded text-[11px]">{{ event.raw_payload.delivery_status.code }}</code>
                        </div>
                        <div v-if="event.raw_payload.delivery_status.message" class="flex gap-2 text-xs">
                          <span class="text-gray-500 flex-shrink-0 min-w-[70px]">Message</span>
                          <span class="text-gray-900 break-all">{{ event.raw_payload.delivery_status.message }}</span>
                        </div>
                        <div v-if="event.raw_payload.delivery_status.description" class="flex gap-2 text-xs">
                          <span class="text-gray-500 flex-shrink-0 min-w-[70px]">Description</span>
                          <span class="text-gray-900 break-all">{{ event.raw_payload.delivery_status.description }}</span>
                        </div>
                        <div v-if="event.raw_payload.delivery_status.mx_host" class="flex gap-2 text-xs">
                          <span class="text-gray-500 flex-shrink-0 min-w-[70px]">MX Host</span>
                          <code class="text-gray-900 bg-gray-200 px-1 py-0.5 rounded text-[11px]">{{ event.raw_payload.delivery_status.mx_host }}</code>
                        </div>
                        <div v-if="event.raw_payload.delivery_status.tls !== undefined" class="flex gap-2 text-xs">
                          <span class="text-gray-500 flex-shrink-0 min-w-[70px]">TLS</span>
                          <span class="text-gray-900">{{ event.raw_payload.delivery_status.tls ? 'Yes' : 'No' }}</span>
                        </div>
                      </div>
                    </div>

                    <!-- Severity/Reason (for bounces) -->
                    <div v-if="event.raw_payload?.severity || event.raw_payload?.reason" class="min-w-0">
                      <h4 class="text-[11px] font-semibold text-gray-500 uppercase tracking-wide mb-2">Failure Info</h4>
                      <div class="flex flex-col gap-1.5">
                        <div v-if="event.raw_payload.severity" class="flex gap-2 text-xs">
                          <span class="text-gray-500 flex-shrink-0 min-w-[70px]">Severity</span>
                          <span class="text-gray-900">{{ event.raw_payload.severity }}</span>
                        </div>
                        <div v-if="event.raw_payload.reason" class="flex gap-2 text-xs">
                          <span class="text-gray-500 flex-shrink-0 min-w-[70px]">Reason</span>
                          <span class="text-gray-900">{{ event.raw_payload.reason }}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                  <p v-else class="m-0 py-2 text-center text-gray-400 text-xs italic">No additional details available</p>
                </div>
              </div>
            </div>
            <p v-else class="p-8 text-center text-gray-500 text-sm">No delivery events yet</p>
          </div>

          <!-- Call Stack tab -->
          <div v-else-if="activeTab === 'stack'" class="h-full">
            <pre class="m-0 p-4 text-xs bg-gray-50 overflow-auto h-full font-mono">{{ email.call_stack?.join('\n') }}</pre>
          </div>

        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { fetchEmail } from '../api/emails'
import StatusBadge from './StatusBadge.vue'

const props = defineProps({
  id: {
    type: [String, Number],
    required: true
  }
})

defineEmits(['close'])

const loading = ref(true)
const error = ref(null)
const email = ref(null)
const config = ref(null)
const activeTab = ref('preview')
const iframeLoading = ref(true)
const expandedEvents = ref(new Set())
const showHeaders = ref(false)

const availableTabs = computed(() => {
  const tabs = [{ id: 'preview', label: 'Preview' }]

  if (config.value?.show_delivery_events) {
    const eventsCount = email.value?.events?.length || 0
    tabs.push({ id: 'events', label: 'Events', count: eventsCount || null })
  }

  if (email.value?.call_stack?.length) {
    tabs.push({ id: 'stack', label: 'Call Stack' })
  }

  return tabs
})

const HIDDEN_HEADERS = ['from', 'to', 'cc', 'bcc', 'subject', 'date']

const filteredHeaders = computed(() => {
  if (!email.value?.headers) return []
  return Object.entries(email.value.headers).filter(
    ([key]) => !HIDDEN_HEADERS.includes(key.toLowerCase())
  )
})

function formatDate(dateString) {
  if (!dateString) return ''
  const date = new Date(dateString)
  return date.toLocaleString()
}

function formatDateTime(dateString) {
  if (!dateString) return ''
  const date = new Date(dateString)
  return date.toLocaleString(undefined, {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  })
}

function toggleEvent(eventId) {
  if (expandedEvents.value.has(eventId)) {
    expandedEvents.value.delete(eventId)
  } else {
    expandedEvents.value.add(eventId)
  }
  // Force reactivity
  expandedEvents.value = new Set(expandedEvents.value)
}

function hasEventDetails(event) {
  return !!(
    event.user_agent ||
    event.client_name ||
    event.ip_address ||
    event.country ||
    event.url ||
    event.raw_payload?.delivery_status ||
    event.raw_payload?.severity ||
    event.raw_payload?.reason
  )
}

function formatHeaderValue(value) {
  if (value === null || value === undefined) return '(empty)'
  if (typeof value === 'object') return JSON.stringify(value, null, 2)
  return String(value)
}

async function loadEmail() {
  loading.value = true
  error.value = null
  try {
    const data = await fetchEmail(props.id)
    email.value = data.email
    config.value = data.config
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

watch(() => props.id, () => {
  activeTab.value = 'preview'
  iframeLoading.value = true
  expandedEvents.value = new Set()
  showHeaders.value = false
  loadEmail()
})

onMounted(() => {
  loadEmail()
})
</script>
