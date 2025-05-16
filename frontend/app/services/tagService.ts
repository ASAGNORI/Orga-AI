import api from './api'

export interface Tag {
  id: string
  name: string
  usage_count: number
}

export const tagService = {
  async getCommonTags(): Promise<Tag[]> {
    const response = await api.get<Tag[]>('/api/v1/tags/common')
    return response.data
  },

  async updateTagUsage(tagName: string): Promise<void> {
    await api.post<void>('/api/v1/tags/update-usage', { tag_name: tagName })
  }
}