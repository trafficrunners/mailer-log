<template>
  <div class="mailer-log-app">
    <AppNavbar />
    <main class="mx-auto px-4 sm:px-6 lg:px-8 py-6">
      <router-view />
    </main>
  </div>
</template>

<script setup>
// This import uses an alias that can be overridden by host application
// See vite.config.js for configuration
import AppNavbar from '@mailer-log/navbar'
</script>
