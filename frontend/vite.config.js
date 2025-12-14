import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'
import { existsSync } from 'fs'

// Allow host application to override components
// Set MAILER_LOG_OVERRIDES_PATH env var to point to overrides directory
// e.g., MAILER_LOG_OVERRIDES_PATH=/path/to/app/mailer_log_overrides
const overridesPath = process.env.MAILER_LOG_OVERRIDES_PATH

function resolveWithOverride(componentPath, defaultPath) {
  if (overridesPath) {
    const overridePath = resolve(overridesPath, componentPath)
    if (existsSync(overridePath)) {
      return overridePath
    }
  }
  return defaultPath
}

export default defineConfig({
  plugins: [vue()],
  base: '/admin/email_log/assets/',
  resolve: {
    alias: {
      // Navbar can be overridden by placing AppNavbar.vue in overrides directory
      '@mailer-log/navbar': resolveWithOverride(
        'AppNavbar.vue',
        resolve(__dirname, 'src/components/AppNavbar.vue')
      ),
      // Add more overridable components here as needed
      '@mailer-log': resolve(__dirname, 'src')
    }
  },
  build: {
    outDir: resolve(__dirname, '../public/mailer_log'),
    emptyOutDir: true,
    manifest: true,
    rollupOptions: {
      input: resolve(__dirname, 'index.html'),
      output: {
        entryFileNames: 'assets/mailer_log-[hash].js',
        chunkFileNames: 'assets/[name]-[hash].js',
        assetFileNames: 'assets/[name]-[hash].[ext]'
      }
    }
  },
  server: {
    cors: true,
    origin: 'http://localhost:5173',
    proxy: {
      '/admin/email_log/api': {
        target: 'http://localhost:3000',
        changeOrigin: true
      }
    }
  }
})
