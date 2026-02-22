import { useState } from 'react'

function AnimatedButton({ children, onClick }: { children: React.ReactNode; onClick?: () => void }) {
  return (
    <button
      onClick={onClick}
      className="group relative inline-flex items-center justify-center px-8 py-3 text-base font-medium text-white rounded-xl overflow-hidden transition-all duration-300 ease-out hover:scale-105 active:scale-95 cursor-pointer"
    >
      {/* Gradient background */}
      <span className="absolute inset-0 bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500 transition-all duration-300 group-hover:opacity-90" />
      
      {/* Shine effect */}
      <span className="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-500">
        <span className="absolute inset-0 translate-x-[-100%] group-hover:translate-x-[100%] transition-transform duration-700 bg-gradient-to-r from-transparent via-white/20 to-transparent" />
      </span>
      
      {/* Glow */}
      <span className="absolute -inset-1 rounded-xl bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500 opacity-0 group-hover:opacity-30 blur-lg transition-opacity duration-300" />
      
      {/* Content */}
      <span className="relative flex items-center gap-2">
        {children}
      </span>
    </button>
  )
}

function App() {
  const [count, setCount] = useState(0)
  const [showMessage, setShowMessage] = useState(false)

  const handleClick = () => {
    setCount(c => c + 1)
    setShowMessage(true)
    setTimeout(() => setShowMessage(false), 2000)
  }

  return (
    <div className="flex flex-col items-center gap-8 text-center">
      <h1 className="text-5xl font-bold bg-gradient-to-r from-indigo-400 via-purple-400 to-pink-400 bg-clip-text text-transparent">
        Hello World! 👋
      </h1>
      
      <p className="text-slate-400 text-lg max-w-md">
        A test app built with Vite + React + TypeScript + Tailwind CSS
      </p>

      <AnimatedButton onClick={handleClick}>
        ✨ Click me!
      </AnimatedButton>

      <div className={`text-slate-300 transition-all duration-300 ${showMessage ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-2'}`}>
        🎉 Clicked {count} {count === 1 ? 'time' : 'times'}!
      </div>
    </div>
  )
}

export default App
