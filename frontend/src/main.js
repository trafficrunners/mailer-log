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

function mountApp() {
  const el = document.getElementById('app')
  if (el) {
    const app = createApp(App)
    app.use(router)
    app.mount(el)
    return true
  }
  return false
}

// #app may be created async by host app's styxie — wait for it
if (!mountApp()) {
  const observer = new MutationObserver(() => {
    if (mountApp()) observer.disconnect()
  })
  observer.observe(document.body, { childList: true, subtree: true })
}
