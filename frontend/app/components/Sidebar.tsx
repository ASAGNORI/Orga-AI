'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import {
  HomeIcon,
  CalendarIcon,
  ListBulletIcon,
  FolderIcon,
  ComputerDesktopIcon,
  ArrowRightOnRectangleIcon
} from '@heroicons/react/24/outline'
import { useAuth } from '../hooks/useAuth'

const navigation = [
  { name: 'Dashboard', href: '/dashboard', icon: HomeIcon },
  { name: 'Calendário', href: '/dashboard/calendar', icon: CalendarIcon },
  { name: 'Tarefas', href: '/dashboard/tasks', icon: ListBulletIcon },
  { name: 'Projetos', href: '/dashboard/projects', icon: FolderIcon },
  { name: 'Web UI', href: '/dashboard/webui', icon: ComputerDesktopIcon },
  // Item de Chat removido, pois agora usamos o chat flutuante
]

export default function Sidebar() {
  const pathname = usePathname()
  const { logout } = useAuth()

  return (
    <div className="flex flex-col w-64 bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700">
      <div className="flex-1 flex flex-col pt-5 pb-4 overflow-y-auto">
        <div className="flex items-center flex-shrink-0 px-4">
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">Orga AI</h1>
        </div>
        <nav className="mt-5 flex-1 px-2 space-y-1">
          {navigation.map((item) => {
            const isActive = pathname === item.href
            return (
              <Link
                key={item.name}
                href={item.href}
                className={`group flex items-center px-2 py-2 text-sm font-medium rounded-md ${
                  isActive
                    ? 'bg-gray-100 dark:bg-gray-700 text-gray-900 dark:text-white'
                    : 'text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700'
                }`}
              >
                <item.icon
                  className={`mr-3 flex-shrink-0 h-6 w-6 ${
                    isActive
                      ? 'text-gray-500 dark:text-gray-300'
                      : 'text-gray-400 dark:text-gray-400 group-hover:text-gray-500 dark:group-hover:text-gray-300'
                  }`}
                  aria-hidden="true"
                />
                {item.name}
              </Link>
            )
          })}
          
          {/* Botão de Logout */}
          <button
            onClick={logout}
            className="w-full mt-4 group flex items-center px-2 py-2 text-sm font-medium rounded-md text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20"
          >
            <ArrowRightOnRectangleIcon
              className="mr-3 flex-shrink-0 h-6 w-6 text-red-500 dark:text-red-400 group-hover:text-red-600"
              aria-hidden="true"
            />
            Logout
          </button>
        </nav>
      </div>
    </div>
  )
}