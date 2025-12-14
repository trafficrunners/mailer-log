import { createApp } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import App from './App.vue'
import './assets/main.css'

import EmailList from './views/EmailList.vue'
import EmailDetail from './views/EmailDetail.vue'

const routes = [
  { path: '/', name: 'emails', component: EmailList },
  { path: '/emails/:id', name: 'email', component: EmailDetail, props: true }
]

const router = createRouter({
  history: createWebHistory('/admin/email_log/'),
  routes
})

const app = createApp(App)
app.use(router)
app.mount('#app')
