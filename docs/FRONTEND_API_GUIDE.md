# Frontend API Integration Guide - Workout Scheduling

## Overview

This guide covers the new scheduling features added to VitalForge API for calendar integration and workout time management.

## New Features

1. **Active Workout Detection** - See which templates user already has active
2. **Scheduled Time** - Set workout time when starting from template
3. **Date Range Filtering** - Query workouts by date range for calendar views (backend)
4. **Duplicate Prevention** - Prevents creating multiple active workouts from same template
5. **Client-Side Template Filtering** - Filter templates by goal, difficulty, frequency on frontend

---

## 1. Browse & Filter Workout Templates

### Endpoint
```
GET /api/v1/workout_templates
```

### No Query Parameters
Backend returns all active templates. **Filtering is done on the frontend.**

### Authentication
- ❌ Not required (public endpoint)
- ✅ Optional - If authenticated, response includes `has_active_workout` flag

### Example Request
```javascript
// Fetch all templates
const response = await fetch('/api/v1/workout_templates');
const { data: templates } = await response.json();

// Filter on frontend
const filteredTemplates = templates.filter(t => 
  t.goal_type === 'physique' && 
  t.difficulty_level === 'Intermediate' &&
  t.days_per_week === 4
);
```

### Response Format
```json
{
  "data": [
    {
      "id": 1,
      "name": "Push Pull Legs",
      "description": "Classic 6-day split for muscle building",
      "goal_type": "physique",
      "difficulty_level": "Intermediate",
      "days_per_week": 6,
      "estimated_duration_minutes": 45,
      "total_exercises": 6,
      "source": "Bodybuilding.com",
      "has_active_workout": false,  // Only present if user is authenticated
      "created_at": "2025-11-01T10:00:00Z",
      "updated_at": "2025-11-01T10:00:00Z"
    }
  ]
}
```

### Frontend Usage

#### Filter Templates (Client-Side)
```javascript
function TemplateFilters({ templates, onFilterChange }) {
  const [filters, setFilters] = useState({
    goal_type: '',
    difficulty_level: '',
    days_per_week: null
  });
  
  useEffect(() => {
    // Apply filters whenever they change
    let filtered = templates;
    
    if (filters.goal_type) {
      filtered = filtered.filter(t => t.goal_type === filters.goal_type);
    }
    
    if (filters.difficulty_level) {
      filtered = filtered.filter(t => t.difficulty_level === filters.difficulty_level);
    }
    
    if (filters.days_per_week) {
      filtered = filtered.filter(t => t.days_per_week === filters.days_per_week);
    }
    
    onFilterChange(filtered);
  }, [filters, templates]);
  
  return (
    <div>
      <select onChange={(e) => setFilters({...filters, goal_type: e.target.value})}>
        <option value="">All Goals</option>
        <option value="physique">Physique</option>
        <option value="strength">Strength</option>
      </select>
      
      <select onChange={(e) => setFilters({...filters, difficulty_level: e.target.value})}>
        <option value="">All Levels</option>
        <option value="Beginner">Beginner</option>
        <option value="Intermediate">Intermediate</option>
        <option value="Advanced">Advanced</option>
      </select>
      
      <select onChange={(e) => setFilters({...filters, days_per_week: parseInt(e.target.value) || null})}>
        <option value="">All Frequencies</option>
        <option value="3">3 days/week</option>
        <option value="4">4 days/week</option>
        <option value="5">5 days/week</option>
        <option value="6">6 days/week</option>
      </select>
    </div>
  );
}
```

#### Show Active Status
```javascript
templates.map(template => (
  <TemplateCard
    key={template.id}
    template={template}
    isActive={template.has_active_workout}
    disabled={template.has_active_workout}
    buttonText={template.has_active_workout ? "Already Active" : "Start Workout"}
  />
))
```

---

## 2. Start Workout from Template (with Scheduled Time)

### Endpoint
```
POST /api/v1/workout_templates/:id/start
```

### Authentication
✅ Required (session or JWT)

### Request Body (optional)
```json
{
  "scheduled_time": "06:00"  // HH:MM format (24-hour)
}
```

### Example Request
```javascript
// Without scheduled time
const response = await fetch('/api/v1/workout_templates/1/start', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': csrfToken
  },
  credentials: 'include'
});

// With scheduled time
const response = await fetch('/api/v1/workout_templates/1/start', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': csrfToken
  },
  credentials: 'include',
  body: JSON.stringify({
    scheduled_time: "06:00"  // 6:00 AM
  })
});
```

### Success Response (201 Created)
```json
{
  "workout": {
    "id": 123,
    "name": "Push Pull Legs",
    "workout_template_id": 1,
    "workout_date": "2025-11-28",
    "scheduled_time": "06:00",
    "started_at": null,
    "completed": false,
    "workout_exercises": [...]
  }
}
```

### Duplicate Error Response (409 Conflict)
```json
{
  "error": "You already have an active workout from this template. Complete it first or view your in-progress workouts.",
  "active_workout_id": 100
}
```

### Frontend Usage

#### Time Picker Component
```javascript
function ScheduleWorkoutModal({ template, onClose, onSuccess }) {
  const [scheduledTime, setScheduledTime] = useState("06:00");
  
  const handleStart = async () => {
    try {
      const response = await fetch(`/api/v1/workout_templates/${template.id}/start`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': getCsrfToken()
        },
        credentials: 'include',
        body: JSON.stringify({
          scheduled_time: scheduledTime
        })
      });
      
      if (response.status === 409) {
        const { error, active_workout_id } = await response.json();
        alert(error);
        // Navigate to active workout: /workouts/${active_workout_id}
        return;
      }
      
      if (response.ok) {
        const { workout } = await response.json();
        onSuccess(workout);
      }
    } catch (error) {
      console.error('Failed to start workout:', error);
    }
  };
  
  return (
    <Modal>
      <h2>{template.name}</h2>
      <label>
        Scheduled Time:
        <input
          type="time"
          value={scheduledTime}
          onChange={(e) => setScheduledTime(e.target.value)}
        />
      </label>
      <button onClick={handleStart}>Start Workout</button>
    </Modal>
  );
}
```

---

## 3. Get Workouts with Date Range

### Endpoint
```
GET /api/v1/workouts
```

### Authentication
✅ Required (session or JWT)

### Query Parameters (all optional)
- `start_date`: ISO date format (YYYY-MM-DD)
- `end_date`: ISO date format (YYYY-MM-DD)

### Example Requests
```javascript
// Get all workouts (default order: most recent first)
fetch('/api/v1/workouts')

// Get workouts for current month
const startOfMonth = "2025-11-01";
const endOfMonth = "2025-11-30";
fetch(`/api/v1/workouts?start_date=${startOfMonth}&end_date=${endOfMonth}`)

// Get upcoming workouts only
const today = new Date().toISOString().split('T')[0];
fetch(`/api/v1/workouts?start_date=${today}`)

// Get past workouts only
fetch(`/api/v1/workouts?end_date=${today}`)
```

### Response Format
```json
{
  "data": [
    {
      "id": 123,
      "name": "Push Pull Legs",
      "workout_date": "2025-11-15",
      "scheduled_time": "06:00",
      "started_at": "2025-11-15T06:05:00Z",
      "completed_at": "2025-11-15T06:50:00Z",
      "completed": true,
      "duration_minutes": 45,
      "workout_template_id": 1,
      "workout_exercises": [...]
    }
  ]
}
```

### Frontend Usage

#### Calendar View
```javascript
function WorkoutCalendar() {
  const [workouts, setWorkouts] = useState([]);
  const [currentMonth, setCurrentMonth] = useState(new Date());
  
  useEffect(() => {
    const startDate = startOfMonth(currentMonth);
    const endDate = endOfMonth(currentMonth);
    
    fetchWorkouts(startDate, endDate);
  }, [currentMonth]);
  
  const fetchWorkouts = async (startDate, endDate) => {
    const start = format(startDate, 'yyyy-MM-dd');
    const end = format(endDate, 'yyyy-MM-dd');
    
    const response = await fetch(
      `/api/v1/workouts?start_date=${start}&end_date=${end}`,
      {
        headers: { 'X-CSRF-Token': getCsrfToken() },
        credentials: 'include'
      }
    );
    
    const { data } = await response.json();
    setWorkouts(data);
  };
  
  return (
    <Calendar>
      {workouts.map(workout => (
        <CalendarEvent
          key={workout.id}
          date={workout.workout_date}
          time={workout.scheduled_time}
          title={workout.name}
          completed={workout.completed}
        />
      ))}
    </Calendar>
  );
}
```

#### Display Scheduled Time
```javascript
function formatWorkoutTime(workout) {
  const date = new Date(workout.workout_date);
  const dateStr = format(date, 'MMM dd, yyyy');
  
  if (workout.scheduled_time) {
    // Convert "06:00" to "6:00 AM"
    const [hours, minutes] = workout.scheduled_time.split(':');
    const hour = parseInt(hours);
    const ampm = hour >= 12 ? 'PM' : 'AM';
    const displayHour = hour % 12 || 12;
    return `${dateStr} at ${displayHour}:${minutes} ${ampm}`;
  }
  
  return dateStr; // No time scheduled
}

// Usage
<p>{formatWorkoutTime(workout)}</p>
// Output: "Nov 15, 2025 at 6:00 AM"
```

---

## 4. ICS Calendar Export (Future)

When ready to implement calendar file export, use this pattern:

### Generate ICS File
```javascript
function generateICS(workouts) {
  const events = workouts.map(workout => {
    const date = workout.workout_date.replace(/-/g, '');
    const time = workout.scheduled_time?.replace(':', '') + '00' || '000000';
    const dtstart = `${date}T${time}`;
    
    return `BEGIN:VEVENT
UID:workout-${workout.id}@vitalforge.com
DTSTAMP:${dtstart}
DTSTART:${dtstart}
SUMMARY:${workout.name}
DESCRIPTION:Workout from ${workout.workout_template_id ? 'template' : 'custom'}
DURATION:PT${workout.duration_minutes || 45}M
END:VEVENT`;
  }).join('\n');
  
  return `BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//VitalForge//Workout Calendar//EN
${events}
END:VCALENDAR`;
}

// Download ICS
function downloadWorkoutCalendar(workouts) {
  const icsContent = generateICS(workouts);
  const blob = new Blob([icsContent], { type: 'text/calendar' });
  const url = URL.createObjectURL(blob);
  
  const link = document.createElement('a');
  link.href = url;
  link.download = 'vitalforge-workouts.ics';
  link.click();
}
```

---

## Error Handling

### Common Error Responses

#### 401 Unauthorized
```json
{
  "error": "You must be logged in to access this resource"
}
```

**Frontend Action:** Redirect to login

#### 404 Not Found
```json
{
  "error": "Template not found"
}
```

**Frontend Action:** Show error message, navigate back

#### 409 Conflict (Duplicate Workout)
```json
{
  "error": "You already have an active workout from this template...",
  "active_workout_id": 100
}
```

**Frontend Action:** Show dialog with option to view active workout

#### 422 Unprocessable Entity
```json
{
  "error": "Validation failed: Workout date can't be blank"
}
```

**Frontend Action:** Show validation errors to user

---

## TypeScript Interfaces

```typescript
interface WorkoutTemplate {
  id: number;
  name: string;
  description: string;
  goal_type: 'physique' | 'strength';
  difficulty_level: 'Beginner' | 'Intermediate' | 'Advanced';
  days_per_week: number;
  estimated_duration_minutes: number;
  total_exercises: number;
  source: string;
  has_active_workout?: boolean;  // Only if authenticated
  created_at: string;
  updated_at: string;
}

interface Workout {
  id: number;
  name: string;
  description: string;
  workout_date: string;  // ISO date
  scheduled_time: string | null;  // "HH:MM" format
  workout_template_id: number | null;
  started_at: string | null;
  completed_at: string | null;
  duration_minutes: number | null;
  workout_type: string;
  completed: boolean;
  workout_exercises: WorkoutExercise[];
}

interface StartWorkoutRequest {
  scheduled_time?: string;  // "HH:MM" format
}

interface WorkoutFilters {
  start_date?: string;  // YYYY-MM-DD
  end_date?: string;    // YYYY-MM-DD
}

interface TemplateFilters {
  goal_type?: 'physique' | 'strength';
  difficulty_level?: 'Beginner' | 'Intermediate' | 'Advanced';
  days_per_week?: number;
}
```

---

## Best Practices

### 1. Time Input Validation
```javascript
function isValidTime(time) {
  const timeRegex = /^([01]\d|2[0-3]):([0-5]\d)$/;
  return timeRegex.test(time);
}
```

### 2. Date Range Validation
```javascript
function isValidDateRange(startDate, endDate) {
  const start = new Date(startDate);
  const end = new Date(endDate);
  return start <= end;
}
```

### 3. Loading States
```javascript
function WorkoutTemplatesList() {
  const [loading, setLoading] = useState(true);
  const [templates, setTemplates] = useState([]);
  
  useEffect(() => {
    fetchTemplates();
  }, []);
  
  if (loading) return <Spinner />;
  if (templates.length === 0) return <EmptyState />;
  
  return <TemplateGrid templates={templates} />;
}
```

### 4. Optimistic UI Updates
```javascript
async function startWorkout(templateId, scheduledTime) {
  // Optimistic update
  const optimisticWorkout = {
    id: 'temp-' + Date.now(),
    name: template.name,
    scheduled_time: scheduledTime,
    completed: false
  };
  
  setWorkouts([optimisticWorkout, ...workouts]);
  
  try {
    const response = await fetch(`/api/v1/workout_templates/${templateId}/start`, {
      method: 'POST',
      body: JSON.stringify({ scheduled_time: scheduledTime })
    });
    
    const { workout } = await response.json();
    
    // Replace optimistic with real data
    setWorkouts(prev => 
      prev.map(w => w.id === optimisticWorkout.id ? workout : w)
    );
  } catch (error) {
    // Rollback optimistic update
    setWorkouts(prev => 
      prev.filter(w => w.id !== optimisticWorkout.id)
    );
    showError('Failed to start workout');
  }
}
```

---

## Testing Checklist

- [ ] Browse templates without authentication
- [ ] Filter templates by goal/difficulty/days
- [ ] See `has_active_workout` flag when logged in
- [ ] Start workout without scheduled time
- [ ] Start workout with scheduled time
- [ ] Try starting duplicate workout (should get 409 error)
- [ ] Get workouts with date range filter
- [ ] Display scheduled time in calendar view
- [ ] Handle all error states gracefully
- [ ] Time picker uses 24-hour format internally
- [ ] Display time in user's preferred format (12/24hr)

---

## Support

For questions or issues:
- Check API documentation: `/api-docs`
- Review Bruno test collection: `/bruno/`
- Contact backend team

