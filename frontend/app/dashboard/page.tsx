'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { useAuth } from '../hooks/useAuth'
import { useStore } from '@/store'
import TaskStats from '../components/TaskStats'

export default function DashboardPage() {
  const router = useRouter();
  const { user, loading, logout } = useAuth();
  const { taskStats, fetchTaskStats } = useStore();

  useEffect(() => {
    if (!loading && !user) {
      router.replace('/login');
    }
  }, [loading, user, router]);

  useEffect(() => {
    if (user) {
      fetchTaskStats();
    }
  }, [user, fetchTaskStats]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500" />
      </div>
    );
  }

  if (!user) {
    return null;
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Dashboard</h1>
      </div>
      
      <TaskStats />
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mt-6">
        <div className="bg-white rounded-lg shadow-lg p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Tasks by Priority</h3>
          <div className="space-y-2">
            {Object.entries(taskStats.byPriority).map(([priority, count]) => (
              <div key={priority} className="flex justify-between items-center">
                <span className="text-gray-800 font-medium capitalize">{priority}</span>
                <span className="text-gray-900 font-semibold">{count}</span>
              </div>
            ))}
          </div>
        </div>
        
        <div className="bg-white rounded-lg shadow-lg p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Top Tags</h3>
          <div className="space-y-2">
            {Object.entries(taskStats.byTag)
              .sort(([, a], [, b]) => b - a)
              .slice(0, 5)
              .map(([tag, count]) => (
                <div key={tag} className="flex justify-between items-center">
                  <span className="text-gray-800 font-medium">#{tag}</span>
                  <span className="text-gray-900 font-semibold">{count}</span>
                </div>
              ))}
          </div>
        </div>
      </div>
    </div>
  );
}