import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

export default defineConfig({
  plugins: [vue()],
  base: '/admin/email_log/assets/',
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
