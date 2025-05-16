export interface Event {
  id: string;
  title: string;
  description: string;
  startDate: string;
  endDate: string;
  color: string;
  userId: string;
  createdAt: string;
  updatedAt: string;
}

export interface CreateEventInput {
  title: string;
  description: string;
  startDate: string;
  endDate: string;
  color: string;
  userId: string;
}

export interface UpdateEventInput extends Partial<CreateEventInput> {
  id: string;
} 