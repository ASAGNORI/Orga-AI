const { createClient } = require('@supabase/supabase-js')

const supabase = createClient(
  'http://localhost:54321',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU'
)

async function createUser() {
  const { data, error } = await supabase.auth.admin.createUser({
    email: 'angelo.sagnori@gmail.com',
    password: 'V123456',
    email_confirm: true
  })

  if (error) {
    console.error('Error creating user:', error.message)
    return
  }

  console.log('User created successfully:', data)
}

createUser() 