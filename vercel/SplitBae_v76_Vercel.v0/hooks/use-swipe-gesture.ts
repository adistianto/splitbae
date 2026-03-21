import { useRef, useState, useEffect } from "react"

interface SwipeGestureOptions {
  onSwipeLeft?: () => void
  onSwipeRight?: () => void
  threshold?: number
}

export function useSwipeGesture({
  onSwipeLeft,
  onSwipeRight,
  threshold = 50,
}: SwipeGestureOptions) {
  const [touchStart, setTouchStart] = useState<number | null>(null)
  const [touchEnd, setTouchEnd] = useState<number | null>(null)
  const ref = useRef<HTMLDivElement>(null)

  const handleTouchStart = (e: TouchEvent) => {
    setTouchStart(e.targetTouches[0].clientX)
  }

  const handleTouchEnd = (e: TouchEvent) => {
    setTouchEnd(e.changedTouches[0].clientX)
  }

  useEffect(() => {
    const element = ref.current
    if (!element) return

    element.addEventListener("touchstart", handleTouchStart, false)
    element.addEventListener("touchend", handleTouchEnd, false)

    return () => {
      element.removeEventListener("touchstart", handleTouchStart, false)
      element.removeEventListener("touchend", handleTouchEnd, false)
    }
  }, [])

  useEffect(() => {
    if (!touchStart || !touchEnd) return

    const distance = touchStart - touchEnd
    const isLeftSwipe = distance > threshold
    const isRightSwipe = distance < -threshold

    if (isLeftSwipe && onSwipeLeft) {
      onSwipeLeft()
    }
    if (isRightSwipe && onSwipeRight) {
      onSwipeRight()
    }
  }, [touchStart, touchEnd, threshold, onSwipeLeft, onSwipeRight])

  return ref
}
