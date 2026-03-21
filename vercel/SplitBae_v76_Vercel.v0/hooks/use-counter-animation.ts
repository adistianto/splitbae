import { useEffect, useRef, useState } from "react"

interface UseCounterAnimationOptions {
  duration?: number
  easing?: (t: number) => number
}

/**
 * Animates a number from 0 to target value
 * Useful for balance displays, totals, counters
 */
export function useCounterAnimation(
  targetValue: number,
  { duration = 600, easing = easeOutQuad }: UseCounterAnimationOptions = {}
) {
  const [displayValue, setDisplayValue] = useState(0)
  const animationRef = useRef<number>()
  const startTimeRef = useRef<number>()
  const startValueRef = useRef(0)

  useEffect(() => {
    startValueRef.current = displayValue
    startTimeRef.current = undefined

    const animate = (currentTime: number) => {
      if (startTimeRef.current === undefined) {
        startTimeRef.current = currentTime
      }

      const elapsedTime = currentTime - startTimeRef.current
      const progress = Math.min(elapsedTime / duration, 1)
      const easedProgress = easing(progress)
      const currentValue = startValueRef.current + (targetValue - startValueRef.current) * easedProgress

      setDisplayValue(currentValue)

      if (progress < 1) {
        animationRef.current = requestAnimationFrame(animate)
      } else {
        animationRef.current = undefined
      }
    }

    animationRef.current = requestAnimationFrame(animate)

    return () => {
      if (animationRef.current !== undefined) {
        cancelAnimationFrame(animationRef.current)
      }
    }
  }, [targetValue, duration, easing])

  return displayValue
}

// Easing functions
function easeOutQuad(t: number): number {
  return 1 - (1 - t) * (1 - t)
}

export function easeInOutQuad(t: number): number {
  return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
}

export function easeOutCubic(t: number): number {
  return 1 + (--t) * t * t
}
