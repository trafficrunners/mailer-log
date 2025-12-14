<template>
  <header class="bg-white shadow">
    <div class="mx-auto px-4 sm:px-6 lg:px-8 py-4">
      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold text-gray-900">
          <router-link to="/" class="hover:text-blue-600">Email Log</router-link>
        </h1>
        <a
          :href="backUrl"
          class="text-sm text-gray-500 hover:text-gray-700 flex items-center gap-1"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/>
          </svg>
          {{ backText }}
        </a>
      </div>
    </div>
  </header>
</template>

<script setup>
defineProps({
  backUrl: {
    type: String,
    default: '/admin/users'
  },
  backText: {
    type: String,
    default: 'Back to Admin'
  }
})
</script>
