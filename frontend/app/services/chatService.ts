import { API_URL } from './api';

export interface ChatMessage {
  message: string;
  context?: any;
}

export interface ChatResponse {
  message: string;
  suggestions?: string[];
  context?: any;
}

export interface ChatHistoryEntry {
  id: string;
  user_id: string;
  user_message: string;
  ai_response: string;
  tags: string[];
  created_at: string;
}

export interface SavedPrompt {
  id: string;
  text: string;
  created_at: string;
}

class ChatService {
  async sendMessage(message: ChatMessage): Promise<ChatResponse> {
    const token = localStorage.getItem('auth_token');
    const response = await fetch(`${API_URL}/api/v1/chat`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
        'Accept': 'application/json'
      },
      body: JSON.stringify(message)
    });
    
    if (!response.ok) {
      throw new Error('Failed to send message');
    }
    
    return response.json();
  }
  
  async getChatHistory(): Promise<ChatHistoryEntry[]> {
    const token = localStorage.getItem('auth_token');
    const response = await fetch(`${API_URL}/api/v1/chat/history`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Accept': 'application/json'
      }
    });
    
    if (!response.ok) {
      throw new Error('Failed to fetch chat history');
    }
    
    return response.json();
  }
  
  async getCommonTags(): Promise<string[]> {
    const token = localStorage.getItem('auth_token');
    const response = await fetch(`${API_URL}/api/v1/chat/tags/common`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Accept': 'application/json'
      }
    });
    
    if (!response.ok) {
      throw new Error('Failed to fetch common tags');
    }
    
    return response.json();
  }

  async deleteChatMessages(ids: string[]): Promise<void> {
    const token = localStorage.getItem('auth_token');
    const response = await fetch(`${API_URL}/api/v1/chat/history`, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: JSON.stringify({ ids })
    });
    
    if (!response.ok) {
      throw new Error('Failed to delete messages');
    }
  }
  
  // New methods for saved prompts
  async getSavedPrompts(): Promise<SavedPrompt[]> {
    const token = localStorage.getItem('auth_token');
    const response = await fetch(`${API_URL}/api/v1/chat/prompts`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Accept': 'application/json'
      }
    });
    
    if (!response.ok) {
      throw new Error('Failed to fetch saved prompts');
    }
    
    return response.json();
  }
  
  async savePrompt(text: string): Promise<SavedPrompt> {
    const token = localStorage.getItem('auth_token');
    const response = await fetch(`${API_URL}/api/v1/chat/prompts`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
        'Accept': 'application/json'
      },
      body: JSON.stringify({ text })
    });
    
    if (!response.ok) {
      throw new Error('Failed to save prompt');
    }
    
    return response.json();
  }
  
  async deletePrompt(id: string): Promise<void> {
    const token = localStorage.getItem('auth_token');
    const response = await fetch(`${API_URL}/api/v1/chat/prompts/${id}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${token}`,
      }
    });
    
    if (!response.ok) {
      throw new Error('Failed to delete prompt');
    }
  }
}

export const chatService = new ChatService();