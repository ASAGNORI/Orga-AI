'use client'

interface LoadingStateProps {
  type?: 'spinner' | 'skeleton' | 'dots'
  size?: 'sm' | 'md' | 'lg'
  text?: string
  fullScreen?: boolean
}

export default function LoadingState({
  type = 'spinner',
  size = 'md',
  text,
  fullScreen = false,
}: LoadingStateProps) {
  const containerClasses = `
    flex flex-col items-center justify-center
    ${fullScreen ? 'fixed inset-0 bg-white/80 dark:bg-gray-900/80 z-50' : 'w-full h-full min-h-[100px]'}
  `

  const sizeClasses = {
    sm: 'h-4 w-4',
    md: 'h-8 w-8',
    lg: 'h-12 w-12',
  }[size]

  const renderLoadingIndicator = () => {
    switch (type) {
      case 'spinner':
        return (
          <div
            className={`animate-spin rounded-full border-t-2 border-b-2 border-indigo-600 ${sizeClasses}`}
            role="status"
            aria-label="Loading"
          />
        )
      case 'dots':
        return (
          <div className="flex space-x-2">
            {[0, 1, 2].map((i) => (
              <div
                key={i}
                className={`
                  bg-indigo-600 rounded-full
                  animate-bounce
                  ${size === 'sm' ? 'h-1.5 w-1.5' : size === 'md' ? 'h-2 w-2' : 'h-3 w-3'}
                `}
                style={{
                  animationDelay: `${i * 0.15}s`,
                }}
              />
            ))}
          </div>
        )
      case 'skeleton':
        return (
          <div className="w-full space-y-3">
            {[0, 1, 2].map((i) => (
              <div
                key={i}
                className={`
                  animate-pulse bg-gray-200 dark:bg-gray-700 rounded
                  ${size === 'sm' ? 'h-2' : size === 'md' ? 'h-4' : 'h-6'}
                `}
                style={{
                  width: `${Math.random() * 30 + 70}%`,
                }}
              />
            ))}
          </div>
        )
    }
  }

  return (
    <div className={containerClasses}>
      {renderLoadingIndicator()}
      {text && (
        <p
          className={`
            mt-4 text-gray-600 dark:text-gray-400
            ${size === 'sm' ? 'text-sm' : size === 'md' ? 'text-base' : 'text-lg'}
          `}
        >
          {text}
        </p>
      )}
    </div>
  )
}