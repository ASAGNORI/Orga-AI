import { NextResponse } from 'next/server'
import createClient from '@/utils/supabase/server'

export async function POST(request: Request) {
  try {
    const { content, context } = await request.json()
    const supabase = createClient()

    // Get current session
    const { data: { session } } = await supabase.auth.getSession()
    if (!session) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      )
    }

    // Forward request to backend AI service
    const response = await fetch(`${process.env.NEXT_PUBLIC_BACKEND_URL}/api/v1/chat`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${session.access_token}`
      },
      body: JSON.stringify({
        message: content,
        context: context || {}
      })
    })

    if (!response.ok) {
      throw new Error('Failed to process message')
    }

    const data = await response.json()
    return NextResponse.json(data)
  } catch (error) {
    console.error('Error in chat processing:', error)
    return NextResponse.json(
      { error: 'Error processing chat message' },
      { status: 500 }
    )
  }
}