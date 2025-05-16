import '../globals.css'

export default function PublicTestLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="public-test-layout">
      {children}
    </div>
  )
} 