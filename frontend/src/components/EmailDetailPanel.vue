<template>
  <div class="email-detail-panel-content">
    <!-- Header -->
    <div class="panel-header">
      <div class="header-content">
        <StatusBadge :status="email?.status" />
        <h2 class="panel-title">{{ email?.subject || '(no subject)' }}</h2>
      </div>
      <button @click="$emit('close')" class="close-btn" title="Close">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
        </svg>
      </button>
    </div>

    <div v-if="loading" class="loading-state">Loading...</div>
    <div v-else-if="error" class="error-state">{{ error }}</div>

    <div v-else-if="email" class="panel-body">
      <!-- Meta info -->
      <div class="meta-section">
        <div class="meta-grid">
          <div class="meta-item">
            <span class="meta-label">From</span>
            <code class="meta-value">{{ email.from_address }}</code>
          </div>
          <div class="meta-item">
            <span class="meta-label">To</span>
            <code class="meta-value">{{ email.to_addresses?.join(', ') }}</code>
          </div>
          <div v-if="email.cc_addresses?.length" class="meta-item">
            <span class="meta-label">CC</span>
            <code class="meta-value">{{ email.cc_addresses.join(', ') }}</code>
          </div>
          <div class="meta-item">
            <span class="meta-label">Mailer</span>
            <code class="meta-value">{{ email.mailer_class }}#{{ email.mailer_action }}</code>
          </div>
          <div class="meta-item">
            <span class="meta-label">Sent</span>
            <span class="meta-value">{{ formatDate(email.created_at) }}</span>
          </div>
          <div v-if="email.delivered_at" class="meta-item">
            <span class="meta-label">Delivered</span>
            <span class="meta-value">{{ formatDate(email.delivered_at) }}</span>
          </div>
          <div v-if="email.opened_at" class="meta-item">
            <span class="meta-label">Opened</span>
            <span class="meta-value">{{ formatDate(email.opened_at) }}</span>
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
              <iframe
                :srcdoc="email.html_body"
                sandbox="allow-same-origin"
                class="preview-iframe"
              />
            </div>
            <pre v-else-if="email.text_body" class="text-preview">{{ email.text_body }}</pre>
            <p v-else class="no-content">No email body available</p>
          </div>

          <!-- Events tab -->
          <div v-else-if="activeTab === 'events'" class="events-content">
            <div v-if="email.events?.length" class="events-list">
              <div v-for="event in email.events" :key="event.id" class="event-item">
                <StatusBadge :status="event.event_type" />
                <span class="event-time">{{ formatTime(event.occurred_at) }}</span>
                <span class="event-recipient">{{ event.recipient }}</span>
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
            <pre class="headers-json">{{ JSON.stringify(email.headers, null, 2) }}</pre>
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
const activeTab = ref('preview')

const availableTabs = computed(() => {
  const tabs = [{ id: 'preview', label: 'Preview' }]

  if (email.value?.events?.length) {
    tabs.push({ id: 'events', label: 'Events', count: email.value.events.length })
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

watch(() => props.id, () => {
  activeTab.value = 'preview'
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
  align-items: flex-start;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.75rem 1rem;
  border-bottom: 1px solid #e5e7eb;
  flex-shrink: 0;
}

.header-content {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  min-width: 0;
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

.close-btn {
  padding: 0.25rem;
  color: #6b7280;
  background: none;
  border: none;
  border-radius: 0.25rem;
  cursor: pointer;
  flex-shrink: 0;
}

.close-btn:hover {
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

.meta-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 0.5rem 1rem;
}

.meta-item {
  display: flex;
  align-items: baseline;
  gap: 0.5rem;
  font-size: 0.8125rem;
}

.meta-label {
  color: #6b7280;
  flex-shrink: 0;
  min-width: 60px;
}

.meta-value {
  color: #111827;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

code.meta-value {
  font-size: 0.75rem;
  background: #f3f4f6;
  padding: 0.125rem 0.25rem;
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
}

.preview-iframe {
  width: 100%;
  height: 100%;
  border: none;
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

.event-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.5rem;
  border-radius: 0.25rem;
}

.event-item:hover {
  background: #f9fafb;
}

.event-time {
  font-size: 0.75rem;
  color: #6b7280;
}

.event-recipient {
  font-size: 0.8125rem;
  color: #374151;
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
.headers-json {
  margin: 0;
  padding: 1rem;
  font-size: 0.75rem;
  background: #f9fafb;
  overflow: auto;
  height: 100%;
}
</style>
