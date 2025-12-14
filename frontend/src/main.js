import { createApp } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import App from './App.vue'
import './assets/main.css'

import EmailLogView from './views/EmailLogView.vue'

const routes = [
  { path: '/', name: 'emails', component: EmailLogView }
]

const router = createRouter({
  history: createWebHistory('/admin/email_log/'),
  routes
})

const app = createApp(App)
app.use(router)
app.mount('#app')
