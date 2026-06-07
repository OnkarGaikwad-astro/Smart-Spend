import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatDateDDMMYYYY(isoString: string | Date): string {
  if (!isoString) return '';
  const d = new Date(isoString);
  const day = d.getDate().toString().padStart(2, '0');
  const month = (d.getMonth() + 1).toString().padStart(2, '0');
  const year = d.getFullYear();
  return `${day}/${month}/${year}`;
}

export function formatDateReadable(isoString: string): string {
  if (!isoString) return '';
  const d = new Date(isoString);
  const now = new Date();
  
  const isToday = d.getDate() === now.getDate() && d.getMonth() === now.getMonth() && d.getFullYear() === now.getFullYear();
  
  const yesterday = new Date(now);
  yesterday.setDate(yesterday.getDate() - 1);
  const isYesterday = d.getDate() === yesterday.getDate() && d.getMonth() === yesterday.getMonth() && d.getFullYear() === yesterday.getFullYear();

  const time = d.toLocaleTimeString(undefined, { hour: 'numeric', minute: '2-digit' });
  
  if (isToday) {
    return `Today, ${time}`;
  } else if (isYesterday) {
    return `Yesterday, ${time}`;
  } else {
    return `${formatDateDDMMYYYY(d)} ${time}`;
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
