<template>
  <div class="date-range-wrapper">
    <div class="date-input-group">
      <VueDatePicker
        v-model="dateRange"
        range
        multi-calendars
        :preset-dates="presetDates"
        :enable-time-picker="false"
        :format="formatDisplay"
        format-locale="en-US"
        placeholder="Any time"
        auto-apply
        :clearable="true"
        hide-input-icon
        @update:model-value="onDateChange"
      >
        <template #preset-date-range-button="{ label, value, presetDate }">
          <button
            type="button"
            class="preset-button"
            @click="presetDate(value)"
          >
            {{ label }}
          </button>
        </template>
      </VueDatePicker>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, computed } from 'vue'
import { VueDatePicker } from '@vuepic/vue-datepicker'
import '@vuepic/vue-datepicker/dist/main.css'

const props = defineProps({
  dateFrom: String,
  dateTo: String
})

const emit = defineEmits(['update:dateFrom', 'update:dateTo'])

const dateRange = ref(null)

// Initialize from props
watch(
  () => [props.dateFrom, props.dateTo],
  ([from, to]) => {
    if (from || to) {
      dateRange.value = [
        from ? new Date(from + 'T00:00:00') : null,
        to ? new Date(to + 'T00:00:00') : null
      ]
    } else {
      dateRange.value = null
    }
  },
  { immediate: true }
)

const presetDates = computed(() => {
  const today = new Date()
  today.setHours(0, 0, 0, 0)

  const yesterday = new Date(today)
  yesterday.setDate(today.getDate() - 1)

  const dayOfWeek = today.getDay()
  const thisWeekStart = new Date(today)
  thisWeekStart.setDate(today.getDate() - (dayOfWeek === 0 ? 6 : dayOfWeek - 1))

  const lastWeekStart = new Date(thisWeekStart)
  lastWeekStart.setDate(thisWeekStart.getDate() - 7)
  const lastWeekEnd = new Date(lastWeekStart)
  lastWeekEnd.setDate(lastWeekStart.getDate() + 6)

  const thisMonthStart = new Date(today.getFullYear(), today.getMonth(), 1)

  const lastMonthStart = new Date(today.getFullYear(), today.getMonth() - 1, 1)
  const lastMonthEnd = new Date(today.getFullYear(), today.getMonth(), 0)

  const last7Days = new Date(today)
  last7Days.setDate(today.getDate() - 6)

  const last30Days = new Date(today)
  last30Days.setDate(today.getDate() - 29)

  return [
    { label: 'Today', value: [today, today] },
    { label: 'Yesterday', value: [yesterday, yesterday] },
    { label: 'This week', value: [thisWeekStart, today] },
    { label: 'Last week', value: [lastWeekStart, lastWeekEnd] },
    { label: 'This month', value: [thisMonthStart, today] },
    { label: 'Last month', value: [lastMonthStart, lastMonthEnd] },
    { label: 'Last 7 days', value: [last7Days, today] },
    { label: 'Last 30 days', value: [last30Days, today] }
  ]
})

function formatDisplay(dates) {
  if (!dates || (!dates[0] && !dates[1])) return ''
  const formatSingle = (d) => {
    if (!d) return ''
    return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
  }
  if (dates[0] && dates[1]) {
    return `${formatSingle(dates[0])} — ${formatSingle(dates[1])}`
  }
  if (dates[0]) {
    return `From ${formatSingle(dates[0])}`
  }
  return ''
}

function formatDateForEmit(date) {
  if (!date) return ''
  return date.toISOString().split('T')[0]
}

function onDateChange(value) {
  if (value && value[0]) {
    emit('update:dateFrom', formatDateForEmit(value[0]))
    emit('update:dateTo', value[1] ? formatDateForEmit(value[1]) : '')
  } else {
    emit('update:dateFrom', '')
    emit('update:dateTo', '')
  }
}
</script>

<style>
/* Vue Datepicker customization */
.dp__theme_light {
  --dp-primary-color: #3b82f6;
  --dp-border-radius: 0.375rem;
  --dp-font-size: 0.875rem;
}

.dp__input {
  font-size: 0.875rem;
  padding: 0.375rem 0.5rem 0.375rem 2rem;
  border: 1px solid #d1d5db;
  border-radius: 0.375rem;
}

.dp__input:hover {
  border-color: #9ca3af;
}

.dp__input:focus {
  border-color: #3b82f6;
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.2);
}

.dp__preset_ranges {
  padding: 0.5rem;
  border-right: 1px solid #e5e7eb;
}

.preset-button {
  display: block;
  width: 100%;
  padding: 0.5rem 0.75rem;
  font-size: 0.8125rem;
  color: #374151;
  background: none;
  border: none;
  border-radius: 0.375rem;
  cursor: pointer;
  text-align: left;
  transition: background 0.1s ease;
}

.preset-button:hover {
  background: #f3f4f6;
}

.dp__menu {
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
}

.date-range-wrapper {
  width: 100%;
}

.date-input-group {
  width: 100%;
}

.date-input-group .dp__input_wrap {
  width: 100%;
}
</style>
