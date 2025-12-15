import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

export default defineConfig({
  plugins: [vue()],
  base: '/mailer_log/',
  resolve: {
    alias: {
      '@mailer-log/navbar': resolve(__dirname, 'src/components/AppNavbar.vue'),
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
    origin: 'http://localhost:5173'
  }
})
