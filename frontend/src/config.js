// Runtime configuration injected by Rails
// Falls back to default for development with Vite dev server

const config = window.MAILER_LOG_CONFIG || {}

export const MOUNT_PATH = config.mountPath || '/admin/mailer-log'
export const API_BASE = `${MOUNT_PATH}/api`
