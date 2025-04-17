from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from enum import IntEnum, Enum
from typing import List, Optional
from pydantic import BaseModel, Field
from datetime import datetime, date

app = FastAPI()

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount the static directory
app.mount("/static", StaticFiles(directory="static"), name="static")


class Priority(IntEnum):
    LOW = 3
    MEDIUM = 2
    HIGH = 1


class TodoArea(str, Enum):
    SPORTS = "sports"
    UNIVERSITY = "university"
    LIFE = "life"
    WORK = "work"


class TodoBase(BaseModel):
    title: str = Field(
        ..., min_length=3, max_length=512, description="Title of the Todo"
    )
    description: str = Field(..., description="Description of the todo")
    priority: Priority = Field(default=Priority.LOW, description="Priority of the todo")
    area: TodoArea = Field(..., description="Area of the todo")
    deadline: date = Field(..., description="Deadline date for the todo")


class TodoCreate(TodoBase):
    pass


class Todo(TodoBase):
    id: int = Field(..., description="Unique identifier of the todo")
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)

    class Config:
        json_encoders = {datetime: lambda v: v.isoformat()}


class TodoUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=3, max_length=512)
    description: Optional[str] = Field(None)
    priority: Optional[Priority] = Field(None)
    area: Optional[TodoArea] = Field(None)
    deadline: Optional[date] = Field(None)


# In-memory storage
todos_db = [
    Todo(
        id=1,
        title="Complete Project",
        description="Finish the FastAPI todo project",
        priority=Priority.HIGH,
        area=TodoArea.WORK,
        deadline=datetime.now().date(),
    ),
    Todo(
        id=2,
        title="Review Code",
        description="Review pull requests",
        priority=Priority.MEDIUM,
        area=TodoArea.WORK,
        deadline=datetime.now().date(),
    ),
]


@app.get("/api/todos", response_model=List[Todo])
async def list_todos(first_n: Optional[int] = None):
    if first_n:
        return todos_db[:first_n]
    return todos_db


@app.get("/api/todos/{todo_id}", response_model=Todo)
async def get_todo(todo_id: int):
    for todo in todos_db:
        if todo.id == todo_id:
            return todo
    raise HTTPException(status_code=404, detail="Todo not found")


@app.post("/api/todos", response_model=Todo)
async def create_todo(todo: TodoCreate):
    new_todo_id = max([todo.id for todo in todos_db], default=0) + 1
    new_todo = Todo(
        id=new_todo_id,
        **todo.dict(),
        created_at=datetime.now(),
        updated_at=datetime.now(),
    )
    todos_db.append(new_todo)
    return new_todo


@app.put("/api/todos/{todo_id}", response_model=Todo)
async def update_todo(todo_id: int, todo_update: TodoUpdate):
    for todo in todos_db:
        if todo.id == todo_id:
            update_data = todo_update.dict(exclude_unset=True)
            for key, value in update_data.items():
                setattr(todo, key, value)
            todo.updated_at = datetime.now()
            return todo
    raise HTTPException(status_code=404, detail="Todo not found")


@app.delete("/api/todos/{todo_id}", response_model=Todo)
async def delete_todo(todo_id: int):
    for index, todo in enumerate(todos_db):
        if todo.id == todo_id:
            return todos_db.pop(index)
    raise HTTPException(status_code=404, detail="Todo not found")


@app.get("/api/todos/deadline/{deadline_date}", response_model=List[Todo])
async def get_todos_by_deadline(deadline_date: date):
    filtered_todos = [todo for todo in todos_db if todo.deadline == deadline_date]
    return filtered_todos


@app.get("/api/todos/area/{area}", response_model=List[Todo])
async def get_todos_by_area(area: TodoArea):
    filtered_todos = [todo for todo in todos_db if todo.area == area]
    return filtered_todos
