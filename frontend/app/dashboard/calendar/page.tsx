'use client'

import { useState, useEffect } from 'react'
import { Calendar as BigCalendar, dateFnsLocalizer, View } from 'react-big-calendar'
import { format, parse, startOfWeek, getDay, addDays } from 'date-fns'
import { enUS } from 'date-fns/locale'
import { toast } from 'react-toastify'
import api from '@/services/api'
import { Button } from '@/components/ui/button'
import 'react-big-calendar/lib/css/react-big-calendar.css'
import { useAuth } from '@/hooks/useAuth'

const locales = {
  'en-US': enUS,
}

const localizer = dateFnsLocalizer({
  format,
  parse,
  startOfWeek,
  getDay,
  locales,
})

// Define all available calendar views
const views = ['month', 'week', 'day', 'agenda']

interface Event {
  id: string
  title: string
  start: Date
  end: Date
  description?: string
  status?: string
  allDay?: boolean
}

interface Task {
  id: string
  title: string
  description?: string
  status: string
  due_date?: string
  created_at: string
  updated_at: string
  user_id?: string
  urgency_score?: number
}

export default function Calendar() {
  const [events, setEvents] = useState<Event[]>([])
  const [loading, setLoading] = useState(true)
  const [date, setDate] = useState(new Date())
  // Restauramos a variável de estado para permitir alternar entre visualizações
  const [view, setView] = useState<View>('month')
  const { user } = useAuth()

  useEffect(() => {
    if (user) {
      fetchEvents()
    }
  }, [user])

  const fetchEvents = async () => {
    try {
      setLoading(true)
      const { data: tasks } = await api.get<Task[]>('/api/v1/tasks')
      
      const formattedEvents = tasks.map(task => {
        let startDate = task.due_date ? new Date(task.due_date) : new Date(task.created_at)
        let endDate = task.due_date ? 
          new Date(new Date(task.due_date).getTime() + 60 * 60 * 1000) : // Add 1 hour to due_date
          new Date(new Date(task.created_at).getTime() + 60 * 60 * 1000)

        // Garantir que as datas estejam no fuso horário local
        startDate = new Date(startDate.getTime() - startDate.getTimezoneOffset() * 60000)
        endDate = new Date(endDate.getTime() - endDate.getTimezoneOffset() * 60000)
        
        return {
          id: task.id,
          title: task.title,
          description: task.description || '',
          start: startDate,
          end: endDate,
          status: task.status,
          allDay: task.due_date ? true : false
        }
      })

      setEvents(formattedEvents)
    } catch (error: any) {
      console.error('Error fetching events:', error)
      toast.error('Failed to fetch events')
    } finally {
      setLoading(false)
    }
  }

  const handleSelectEvent = (event: Event) => {
    toast.info(`${event.title} - ${event.status || 'No status'}`)
  }

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    )
  }

  return (
    <div className="h-[600px] flex flex-col gap-4">
      <div className="grid grid-cols-3 mb-4 items-center w-full">
        {/* Botões de navegação - coluna esquerda */}
        <div className="flex gap-2 items-center">
          <Button
            variant="outline"
            onClick={() => setDate(new Date())}
          >
            Today
          </Button>
          <Button
            variant="outline"
            onClick={() => {
              const newDate = new Date(date);
              if (view === 'month') {
                newDate.setMonth(date.getMonth() - 1);
              } else if (view === 'week') {
                newDate.setDate(date.getDate() - 7);
              } else if (view === 'day') {
                newDate.setDate(date.getDate() - 1);
              }
              setDate(newDate);
            }}
          >
            Back
          </Button>
          <Button
            variant="outline"
            onClick={() => {
              const newDate = new Date(date);
              if (view === 'month') {
                newDate.setMonth(date.getMonth() + 1);
              } else if (view === 'week') {
                newDate.setDate(date.getDate() + 7);
              } else if (view === 'day') {
                newDate.setDate(date.getDate() + 1);
              }
              setDate(newDate);
            }}
          >
            Next
          </Button>
        </div>
        
        {/* Data centralizada - coluna central */}
        <div className="flex justify-center items-center text-lg font-medium">
          {view === 'month' && format(date, 'MMMM yyyy')}
          {view === 'week' && `${format(date, 'dd/MM/yyyy')} - ${format(new Date(date.getTime() + 6 * 24 * 60 * 60 * 1000), 'dd/MM/yyyy')}`}
          {view === 'day' && format(date, 'dd/MM/yyyy')}
          {view === 'agenda' && format(date, 'MMMM yyyy')}
        </div>
        
        {/* Botões de visualização - coluna direita */}
        <div className="flex gap-2 justify-end">
          <Button
            variant={view === 'month' ? 'default' : 'outline'}
            onClick={() => setView('month')}
            size="sm"
          >
            Month
          </Button>
          <Button
            variant={view === 'week' ? 'default' : 'outline'}
            onClick={() => setView('week')}
            size="sm"
          >
            Week
          </Button>
          <Button
            variant={view === 'day' ? 'default' : 'outline'}
            onClick={() => setView('day')}
            size="sm"
          >
            Day
          </Button>
          <Button
            variant={view === 'agenda' ? 'default' : 'outline'}
            onClick={() => setView('agenda')}
            size="sm"
          >
            Agenda
          </Button>
        </div>
      </div>
      
      <BigCalendar
        localizer={localizer}
        events={events}
        startAccessor="start"
        endAccessor="end"
        onSelectEvent={handleSelectEvent}
        style={{ height: 'calc(100% - 48px)' }}
        view={view}
        onView={setView as (view: string) => void}
        date={date}
        onNavigate={(newDate: Date) => setDate(newDate)}
        defaultView="week"
        toolbar={false}
        popup={true}
        selectable={true}
        eventPropGetter={(event) => ({
          style: {
            backgroundColor: event.status === 'done' ? '#10b981' : // green for done
                           event.status === 'in_progress' ? '#f59e0b' : // yellow for in progress
                           '#ef4444' // red for todo
          }
        })}
      />
    </div>
  )
}