import { API_BASE } from '../config'

export async function fetchEmails(params = {}) {
  const searchParams = new URLSearchParams()

  Object.entries(params).forEach(([key, value]) => {
    if (value !== null && value !== undefined && value !== '') {
      searchParams.append(key, value)
    }
  })

  const url = `${API_BASE}/emails?${searchParams.toString()}`
  const response = await fetch(url, {
    headers: {
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest'
    },
    credentials: 'same-origin'
  })

  if (!response.ok) {
    throw new Error(`Failed to fetch emails: ${response.statusText}`)
  }

  return response.json()
}

export async function fetchEmail(id) {
  const response = await fetch(`${API_BASE}/emails/${id}`, {
    headers: {
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest'
    },
    credentials: 'same-origin'
  })

  if (!response.ok) {
    throw new Error(`Failed to fetch email: ${response.statusText}`)
  }

  return response.json()
}

export async function fetchMailers() {
  const response = await fetch(`${API_BASE}/mailers`, {
    headers: {
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest'
    },
    credentials: 'same-origin'
  })

  if (!response.ok) {
    throw new Error(`Failed to fetch mailers: ${response.statusText}`)
  }

  return response.json()
}
