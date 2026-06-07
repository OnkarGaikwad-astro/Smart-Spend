import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatDateReadable(isoString: string): string {
  if (!isoString) return '';
  const date = new Date(isoString);
  const now = new Date();
  
  const isToday = date.getDate() === now.getDate() && date.getMonth() === now.getMonth() && date.getFullYear() === now.getFullYear();
  
  const yesterday = new Date(now);
  yesterday.setDate(yesterday.getDate() - 1);
  const isYesterday = date.getDate() === yesterday.getDate() && date.getMonth() === yesterday.getMonth() && date.getFullYear() === yesterday.getFullYear();

  if (isToday) {
    return `Today, ${date.toLocaleTimeString(undefined, { hour: 'numeric', minute: '2-digit' })}`;
  } else if (isYesterday) {
    return `Yesterday, ${date.toLocaleTimeString(undefined, { hour: 'numeric', minute: '2-digit' })}`;
  } else {
    return new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
    hour12: true
  }).format(date);
  }
}
export const getIcon = (name: string, type?: 'INCOME' | 'EXPENSE') => {
  switch (name?.toLowerCase()) {
    // Expense Categories
    case 'food': case 'pizza': case 'food delivery': return "🍔";
    case 'transport': case 'car': case 'uber': return "🚗";
    case 'subscriptions': case 'music': case 'spotify': return "🎵";
    case 'entertainment': case 'movies': return "🎬";
    case 'shopping': case 'clothes': return "🛍️";
    case 'bills': case 'utilities': return "💡";
    case 'savings': return "🐷";
    
    // Income Categories (Student Focus)
    case 'scholarship': return "🎓";
    case 'parents': return "👨‍👩‍👧‍👦";
    case 'sister': return "👧";
    case 'friends': return "🤝";
    case 'salary': return "💰";
    case 'freelance': case 'briefcase': return "💼";
    case 'investment': return "📈";
    case 'gift': return "🎁";
    
    // Default Fallbacks
    case 'receipt': return "🧾";
    default: return type === 'INCOME' ? "💵" : "📄";
  }
};
