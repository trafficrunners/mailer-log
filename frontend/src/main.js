import { createApp } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import App from './App.vue'
import './assets/main.css'
import { MOUNT_PATH } from './config'

import EmailLogView from './views/EmailLogView.vue'

const routes = [
  { path: '/', name: 'emails', component: EmailLogView }
]

const router = createRouter({
  history: createWebHistory(`${MOUNT_PATH}/`),
  routes
})

const app = createApp(App)
app.use(router)
app.mount('#app')
