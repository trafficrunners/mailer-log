<template>
  <div class="email-detail-panel-content">
    <!-- Header -->
    <div class="panel-header">
      <button @click="$emit('close')" class="back-btn" title="Close">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
        </svg>
      </button>
      <div class="header-content">
        <StatusBadge :status="email?.status" />
        <h2 class="panel-title">{{ email?.subject || '(no subject)' }}</h2>
      </div>
    </div>

    <div v-if="loading" class="loading-state">Loading...</div>
    <div v-else-if="error" class="error-state">{{ error }}</div>

    <div v-else-if="email" class="panel-body">
      <!-- Meta info -->
      <div class="meta-section">
        <div class="meta-layout">
          <!-- Left: From/To stacked vertically -->
          <div class="meta-addresses">
            <div class="address-row">
              <span class="address-label">From</span>
              <code
                class="address-value"
                :title="email.from_address"
              >{{ email.from_address }}</code>
            </div>
            <div class="address-row">
              <span class="address-label">To</span>
              <code
                class="address-value"
                :title="email.to_addresses?.join(', ')"
              >{{ email.to_addresses?.join(', ') }}</code>
            </div>
            <div v-if="email.cc_addresses?.length" class="address-row">
              <span class="address-label">CC</span>
              <code
                class="address-value"
                :title="email.cc_addresses.join(', ')"
              >{{ email.cc_addresses.join(', ') }}</code>
            </div>
          </div>

          <!-- Right: Date & Mailer -->
          <div class="meta-info">
            <div class="info-item">
              <span class="info-label">Sent</span>
              <span class="info-value">{{ formatDate(email.created_at) }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">Mailer</span>
              <code class="info-value">{{ email.mailer_class }}#{{ email.mailer_action }}</code>
            </div>
          </div>
        </div>
      </div>

      <!-- Tabs -->
      <div class="tabs-section">
        <div class="tabs-header">
          <button
            v-for="tab in availableTabs"
            :key="tab.id"
            @click="activeTab = tab.id"
            :class="['tab-btn', { active: activeTab === tab.id }]"
          >
            {{ tab.label }}
            <span v-if="tab.count" class="tab-count">{{ tab.count }}</span>
          </button>
        </div>

        <div class="tab-content">
          <!-- Preview tab -->
          <div v-if="activeTab === 'preview'" class="preview-content">
            <div v-if="email.html_body" class="html-preview">
              <div v-if="iframeLoading" class="iframe-loading">Loading preview...</div>
              <iframe
                :srcdoc="email.html_body"
                sandbox="allow-same-origin"
                class="preview-iframe"
                :class="{ 'is-loading': iframeLoading }"
                @load="iframeLoading = false"
              />
            </div>
            <pre v-else-if="email.text_body" class="text-preview">{{ email.text_body }}</pre>
            <p v-else class="no-content">No email body available</p>
          </div>

          <!-- Events tab -->
          <div v-else-if="activeTab === 'events'" class="events-content">
            <div v-if="email.events?.length" class="events-list">
              <div
                v-for="event in email.events"
                :key="event.id"
                class="event-item-wrapper"
              >
                <div
                  class="event-item"
                  :class="{ expanded: expandedEvents.has(event.id) }"
                  @click="toggleEvent(event.id)"
                >
                  <div class="event-main">
                    <StatusBadge :status="event.event_type" />
                    <span class="event-time">{{ formatDateTime(event.occurred_at) }}</span>
                    <span class="event-recipient">{{ event.recipient }}</span>
                  </div>
                  <div class="event-summary">
                    <span v-if="event.city || event.country" class="event-location">
                      {{ [event.city, event.country].filter(Boolean).join(', ') }}
                    </span>
                    <span v-if="event.device_type" class="event-device">
                      {{ event.device_type }}
                    </span>
                    <svg
                      class="expand-icon"
                      :class="{ rotated: expandedEvents.has(event.id) }"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
                    </svg>
                  </div>
                </div>
                <div v-if="expandedEvents.has(event.id)" class="event-details">
                  <div v-if="hasEventDetails(event)" class="details-grid">
                    <!-- Client Info -->
                    <div v-if="event.user_agent || event.client_name" class="detail-section">
                      <h4 class="detail-title">Client Info</h4>
                      <div class="detail-rows">
                        <div v-if="event.client_name" class="detail-row">
                          <span class="detail-label">Client</span>
                          <span class="detail-value">{{ event.client_name }}</span>
                        </div>
                        <div v-if="event.client_os" class="detail-row">
                          <span class="detail-label">OS</span>
                          <span class="detail-value">{{ event.client_os }}</span>
                        </div>
                        <div v-if="event.device_type" class="detail-row">
                          <span class="detail-label">Device</span>
                          <span class="detail-value">{{ event.device_type }}</span>
                        </div>
                        <div v-if="event.user_agent" class="detail-row">
                          <span class="detail-label">User Agent</span>
                          <span class="detail-value detail-value-wrap">{{ event.user_agent }}</span>
                        </div>
                      </div>
                    </div>

                    <!-- Location -->
                    <div v-if="event.ip_address || event.country" class="detail-section">
                      <h4 class="detail-title">Location</h4>
                      <div class="detail-rows">
                        <div v-if="event.ip_address" class="detail-row">
                          <span class="detail-label">IP Address</span>
                          <code class="detail-value">{{ event.ip_address }}</code>
                        </div>
                        <div v-if="event.country" class="detail-row">
                          <span class="detail-label">Country</span>
                          <span class="detail-value">{{ event.country }}</span>
                        </div>
                        <div v-if="event.region" class="detail-row">
                          <span class="detail-label">Region</span>
                          <span class="detail-value">{{ event.region }}</span>
                        </div>
                        <div v-if="event.city" class="detail-row">
                          <span class="detail-label">City</span>
                          <span class="detail-value">{{ event.city }}</span>
                        </div>
                      </div>
                    </div>

                    <!-- URL (for clicks) -->
                    <div v-if="event.url" class="detail-section detail-section-full">
                      <h4 class="detail-title">Clicked URL</h4>
                      <a :href="event.url" target="_blank" class="clicked-url">{{ event.url }}</a>
                    </div>

                    <!-- Delivery Status (for delivered/bounced) -->
                    <div v-if="event.raw_payload?.delivery_status" class="detail-section detail-section-full">
                      <h4 class="detail-title">Delivery Status</h4>
                      <div class="detail-rows">
                        <div v-if="event.raw_payload.delivery_status.code" class="detail-row">
                          <span class="detail-label">Code</span>
                          <code class="detail-value">{{ event.raw_payload.delivery_status.code }}</code>
                        </div>
                        <div v-if="event.raw_payload.delivery_status.message" class="detail-row">
                          <span class="detail-label">Message</span>
                          <span class="detail-value detail-value-wrap">{{ event.raw_payload.delivery_status.message }}</span>
                        </div>
                        <div v-if="event.raw_payload.delivery_status.description" class="detail-row">
                          <span class="detail-label">Description</span>
                          <span class="detail-value detail-value-wrap">{{ event.raw_payload.delivery_status.description }}</span>
                        </div>
                        <div v-if="event.raw_payload.delivery_status.mx_host" class="detail-row">
                          <span class="detail-label">MX Host</span>
                          <code class="detail-value">{{ event.raw_payload.delivery_status.mx_host }}</code>
                        </div>
                        <div v-if="event.raw_payload.delivery_status.tls !== undefined" class="detail-row">
                          <span class="detail-label">TLS</span>
                          <span class="detail-value">{{ event.raw_payload.delivery_status.tls ? 'Yes' : 'No' }}</span>
                        </div>
                      </div>
                    </div>

                    <!-- Severity/Reason (for bounces) -->
                    <div v-if="event.raw_payload?.severity || event.raw_payload?.reason" class="detail-section">
                      <h4 class="detail-title">Failure Info</h4>
                      <div class="detail-rows">
                        <div v-if="event.raw_payload.severity" class="detail-row">
                          <span class="detail-label">Severity</span>
                          <span class="detail-value">{{ event.raw_payload.severity }}</span>
                        </div>
                        <div v-if="event.raw_payload.reason" class="detail-row">
                          <span class="detail-label">Reason</span>
                          <span class="detail-value">{{ event.raw_payload.reason }}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                  <p v-else class="no-details">No additional details available</p>
                </div>
              </div>
            </div>
            <p v-else class="no-content">No delivery events yet</p>
          </div>

          <!-- Call Stack tab -->
          <div v-else-if="activeTab === 'stack'" class="stack-content">
            <pre class="stack-trace">{{ email.call_stack }}</pre>
          </div>

          <!-- Headers tab -->
          <div v-else-if="activeTab === 'headers'" class="headers-content">
            <div v-if="email.headers && Object.keys(email.headers).length" class="headers-panel">
              <div class="detail-rows">
                <div v-for="(value, key) in email.headers" :key="key" class="detail-row">
                  <span class="detail-label">{{ key }}</span>
                  <span class="detail-value detail-value-wrap">{{ formatHeaderValue(value) }}</span>
                </div>
              </div>
            </div>
            <p v-else class="no-content">No headers available</p>
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

const availableTabs = computed(() => {
  const tabs = [{ id: 'preview', label: 'Preview' }]

  if (config.value?.show_delivery_events) {
    const eventsCount = email.value?.events?.length || 0
    tabs.push({ id: 'events', label: 'Events', count: eventsCount || null })
  }

  if (email.value?.call_stack) {
    tabs.push({ id: 'stack', label: 'Call Stack' })
  }

  if (email.value?.headers && Object.keys(email.value.headers).length) {
    tabs.push({ id: 'headers', label: 'Headers' })
  }

  return tabs
})

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
  loadEmail()
})

onMounted(() => {
  loadEmail()
})
</script>

<style scoped>
.email-detail-panel-content {
  display: flex;
  flex-direction: column;
  height: 100%;
}

/* Header */
.panel-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1rem;
  border-bottom: 1px solid #e5e7eb;
  flex-shrink: 0;
}

.header-content {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  min-width: 0;
  flex: 1;
}

.panel-title {
  font-size: 0.9375rem;
  font-weight: 600;
  color: #111827;
  margin: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.back-btn {
  padding: 0.375rem;
  color: #6b7280;
  background: none;
  border: none;
  border-radius: 0.25rem;
  cursor: pointer;
  flex-shrink: 0;
}

.back-btn:hover {
  color: #374151;
  background: #f3f4f6;
}

/* States */
.loading-state,
.error-state {
  padding: 2rem;
  text-align: center;
  color: #6b7280;
}

.error-state {
  color: #dc2626;
}

/* Body */
.panel-body {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
  overflow: hidden;
}

/* Meta section */
.meta-section {
  padding: 0.75rem 1rem;
  border-bottom: 1px solid #e5e7eb;
  flex-shrink: 0;
}

.meta-layout {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
}

/* Left: From/To addresses stacked */
.meta-addresses {
  display: flex;
  flex-direction: column;
  gap: 0.375rem;
  min-width: 0;
  flex: 1;
}

.address-row {
  display: flex;
  align-items: baseline;
  gap: 0.5rem;
  font-size: 0.8125rem;
}

.address-label {
  color: #6b7280;
  flex-shrink: 0;
  min-width: 32px;
}

.address-value {
  color: #111827;
  font-size: 0.75rem;
  background: #f3f4f6;
  padding: 0.125rem 0.375rem;
  border-radius: 0.25rem;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 100%;
  cursor: default;
}

/* Right: Mailer info & date */
.meta-info {
  display: flex;
  flex-direction: column;
  gap: 0.375rem;
  flex-shrink: 0;
  text-align: right;
}

.info-item {
  display: flex;
  align-items: baseline;
  justify-content: flex-end;
  gap: 0.5rem;
  font-size: 0.8125rem;
}

.info-label {
  color: #6b7280;
}

.info-value {
  color: #111827;
}

code.info-value {
  font-size: 0.75rem;
  background: #f3f4f6;
  padding: 0.125rem 0.375rem;
  border-radius: 0.25rem;
}

/* Tabs */
.tabs-section {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
}

.tabs-header {
  display: flex;
  gap: 0.25rem;
  padding: 0.5rem 1rem 0;
  border-bottom: 1px solid #e5e7eb;
  flex-shrink: 0;
}

.tab-btn {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  padding: 0.5rem 0.75rem;
  font-size: 0.8125rem;
  font-weight: 500;
  color: #6b7280;
  background: none;
  border: none;
  border-bottom: 2px solid transparent;
  margin-bottom: -1px;
  cursor: pointer;
}

.tab-btn:hover {
  color: #374151;
}

.tab-btn.active {
  color: #3b82f6;
  border-bottom-color: #3b82f6;
}

.tab-count {
  font-size: 0.6875rem;
  background: #e5e7eb;
  color: #374151;
  padding: 0.125rem 0.375rem;
  border-radius: 9999px;
}

.tab-btn.active .tab-count {
  background: #dbeafe;
  color: #3b82f6;
}

/* Tab content */
.tab-content {
  flex: 1;
  overflow: auto;
}

.preview-content,
.events-content,
.stack-content,
.headers-content {
  height: 100%;
}

/* Preview */
.html-preview {
  height: 100%;
  position: relative;
}

.iframe-loading {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f9fafb;
  color: #6b7280;
  font-size: 0.875rem;
}

.preview-iframe {
  width: 100%;
  height: 100%;
  border: none;
  opacity: 1;
  transition: opacity 0.15s ease;
}

.preview-iframe.is-loading {
  opacity: 0;
}

.text-preview {
  margin: 0;
  padding: 1rem;
  font-size: 0.8125rem;
  background: #f9fafb;
  overflow: auto;
  height: 100%;
}

.no-content {
  padding: 2rem;
  text-align: center;
  color: #6b7280;
  font-size: 0.875rem;
}

/* Events */
.events-list {
  padding: 0.5rem;
}

.event-item-wrapper {
  margin-bottom: 0.25rem;
}

.event-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
  padding: 0.625rem 0.75rem;
  border-radius: 0.375rem;
  cursor: pointer;
  border: 1px solid transparent;
  transition: all 0.15s ease;
}

.event-item:hover {
  background: #f9fafb;
}

.event-item.expanded {
  background: #f3f4f6;
  border-color: #e5e7eb;
  border-radius: 0.375rem 0.375rem 0 0;
}

.event-main {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  min-width: 0;
}

.event-summary {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex-shrink: 0;
}

.event-time {
  font-size: 0.75rem;
  color: #6b7280;
  white-space: nowrap;
}

.event-recipient {
  font-size: 0.8125rem;
  color: #374151;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.event-location,
.event-device {
  font-size: 0.6875rem;
  color: #9ca3af;
  background: #f3f4f6;
  padding: 0.125rem 0.5rem;
  border-radius: 9999px;
}

.expand-icon {
  width: 1rem;
  height: 1rem;
  color: #9ca3af;
  flex-shrink: 0;
  transition: transform 0.2s ease;
}

.expand-icon.rotated {
  transform: rotate(180deg);
}

/* Event Details */
.event-details {
  background: #f9fafb;
  border: 1px solid #e5e7eb;
  border-top: none;
  border-radius: 0 0 0.375rem 0.375rem;
  padding: 0.75rem;
  margin-bottom: 0.5rem;
}

.details-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1rem;
}

.detail-section {
  min-width: 0;
}

.detail-section-full {
  grid-column: 1 / -1;
}

.detail-title {
  font-size: 0.6875rem;
  font-weight: 600;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin: 0 0 0.5rem 0;
}

.detail-rows {
  display: flex;
  flex-direction: column;
  gap: 0.375rem;
}

.detail-row {
  display: flex;
  gap: 0.5rem;
  font-size: 0.75rem;
  line-height: 1.4;
}

.detail-label {
  color: #6b7280;
  flex-shrink: 0;
  min-width: 70px;
}

.detail-value {
  color: #111827;
  word-break: break-word;
}

.detail-value-wrap {
  word-break: break-all;
}

code.detail-value {
  font-family: ui-monospace, monospace;
  background: #e5e7eb;
  padding: 0.0625rem 0.25rem;
  border-radius: 0.25rem;
  font-size: 0.6875rem;
}

.clicked-url {
  display: block;
  font-size: 0.75rem;
  color: #3b82f6;
  word-break: break-all;
  text-decoration: none;
  padding: 0.375rem 0.5rem;
  background: #eff6ff;
  border-radius: 0.25rem;
  border: 1px solid #dbeafe;
}

.clicked-url:hover {
  text-decoration: underline;
  background: #dbeafe;
}

.no-details {
  margin: 0;
  padding: 0.5rem 0;
  text-align: center;
  color: #9ca3af;
  font-size: 0.75rem;
  font-style: italic;
}

/* Stack trace */
.stack-trace {
  margin: 0;
  padding: 1rem;
  font-size: 0.75rem;
  background: #f9fafb;
  overflow: auto;
  height: 100%;
}

/* Headers */
.headers-content {
  background: #f9fafb;
  height: 100%;
  overflow: auto;
}

.headers-panel {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 0.375rem;
  margin: 0.75rem;
  padding: 0.75rem;
}

.headers-panel .detail-label {
  min-width: 140px;
  font-family: ui-monospace, monospace;
}

.headers-panel .detail-value {
  font-family: ui-monospace, monospace;
}
</style>
