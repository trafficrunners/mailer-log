<template>
  <div class="mailer-log-app">
    <AppNavbar v-if="!hideNavbar" />
    <main class="mx-auto px-4 sm:px-6 lg:px-8 py-6">
      <router-view />
    </main>
  </div>
</template>

<script setup>
import AppNavbar from '@mailer-log/navbar'

const config = window.MAILER_LOG_CONFIG || {}
const hideNavbar = config.hideNavbar || false
</script>
