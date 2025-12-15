<template>
  <span :class="badgeClasses" :title="status">
    <template v-if="compact">{{ icon }}</template>
    <template v-else>{{ status }}</template>
  </span>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  status: {
    type: String,
    required: true
  },
  compact: {
    type: Boolean,
    default: false
  }
})

const icon = computed(() => {
  switch (props.status) {
    case 'delivered': return '✓'
    case 'opened': return '◉'
    case 'clicked': return '↗'
    case 'bounced': return '✗'
    case 'complained': return '⚠'
    case 'sent': return '→'
    case 'pending':
    default: return '○'
  }
})

const badgeClasses = computed(() => {
  const base = props.compact
    ? 'inline-flex items-center justify-center w-5 h-5 rounded-full text-xs font-medium'
    : 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium'

  switch (props.status) {
    case 'delivered':
    case 'opened':
    case 'clicked':
      return `${base} bg-green-100 text-green-800`
    case 'bounced':
    case 'complained':
      return `${base} bg-red-100 text-red-800`
    case 'sent':
      return `${base} bg-blue-100 text-blue-800`
    case 'pending':
    default:
      return `${base} bg-gray-100 text-gray-800`
  }
})
</script>
