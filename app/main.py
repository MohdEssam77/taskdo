from fastapi import FastAPI, HTTPException, Depends, status, Request, Query
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from enum import IntEnum, Enum
from typing import List, Optional
from pydantic import BaseModel, Field, EmailStr
from datetime import datetime, date, timedelta
from passlib.context import CryptContext
from jose import JWTError, jwt
import os
from dotenv import load_dotenv
from database import (
    get_user,
    create_user,
    get_todo,
    get_user_todos,
    create_todo,
    update_todo,
    delete_todo,
    get_todos_by_deadline,
    get_todos_by_area,
    users_collection,
    todos_collection,
    search_todos,
)

# Load environment variables
load_dotenv()

# Security configuration
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-for-development")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/token")

app = FastAPI()

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)


# Request logging middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    print(f"Received request: {request.method} {request.url}")
    print(f"Headers: {request.headers}")
    response = await call_next(request)
    print(f"Response status: {response.status_code}")
    return response


class Priority(IntEnum):
    LOW = 3
    MEDIUM = 2
    HIGH = 1


class TodoArea(str, Enum):
    SPORTS = "sports"
    UNIVERSITY = "university"
    LIFE = "life"
    WORK = "work"


# User models
class UserBase(BaseModel):
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=50)


class UserCreate(UserBase):
    password: str = Field(..., min_length=6)


class User(UserBase):
    id: int
    is_active: bool = True
    created_at: datetime = Field(default_factory=datetime.now)


class UserInDB(User):
    hashed_password: str


class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    username: Optional[str] = None


# Todo models with user relationship
class TodoBase(BaseModel):
    title: str = Field(..., min_length=3, max_length=512)
    description: Optional[str] = Field(None)
    completed: bool = Field(False)
    priority: Optional[Priority] = Field(None)
    area: Optional[TodoArea] = Field(None)
    deadline: Optional[date] = Field(None)


class TodoCreate(BaseModel):
    title: str = Field(..., min_length=3, max_length=512)
    description: Optional[str] = Field(None)
    completed: bool = Field(False)
    priority: Optional[Priority] = Field(None)
    area: Optional[TodoArea] = Field(None)
    deadline: Optional[date] = Field(None)


class Todo(TodoCreate):
    id: int = Field(..., description="Unique identifier of the todo")
    user_id: int = Field(..., description="ID of the user who owns this todo")
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)

    class Config:
        json_encoders = {datetime: lambda v: v.isoformat()}


class TodoUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=3, max_length=512)
    description: Optional[str] = Field(None)
    completed: Optional[bool] = Field(None)
    priority: Optional[Priority] = Field(None)
    area: Optional[TodoArea] = Field(None)
    deadline: Optional[date] = Field(None)


class TodoFilter(BaseModel):
    area: Optional[TodoArea] = Field(None)
    deadline: Optional[date] = Field(None)
    sort_by_deadline: Optional[bool] = Field(
        False, description="Sort todos by deadline"
    )


def authenticate_user(username: str, password: str):
    user = get_user(username)
    if not user:
        return False
    if not verify_password(password, user["hashed_password"]):
        return False
    return user


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password):
    return pwd_context.hash(password)


async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
        token_data = TokenData(username=username)
    except JWTError:
        raise credentials_exception
    user = get_user(username=token_data.username)
    if user is None:
        raise credentials_exception
    return user


# Auth endpoints
@app.post("/api/register", response_model=User)
async def register(user: UserCreate):
    if get_user(user.username):
        raise HTTPException(status_code=400, detail="Username already registered")

    # Get the current number of users to generate a new ID
    users_count = users_collection.count_documents({})
    db_user = {
        "id": users_count + 1,  # Generate a new ID based on user count
        "email": user.email,
        "username": user.username,
        "hashed_password": get_password_hash(user.password),
        "is_active": True,
        "created_at": datetime.now(),
    }
    created_user = create_user(db_user)
    return created_user


@app.post("/api/token", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    user = authenticate_user(form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user["username"]}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}


@app.post("/api/forgot-password")
async def forgot_password(email: str):
    # In a real application, you would:
    # 1. Verify the email exists
    # 2. Generate a password reset token
    # 3. Send an email with reset instructions
    # For this demo, we'll just return a success message
    return {"message": "If the email exists, password reset instructions will be sent"}


# Updated todo endpoints to include user authentication
@app.post("/api/todos", response_model=Todo)
async def create_todo_endpoint(
    todo: TodoCreate, current_user: dict = Depends(get_current_user)
):
    new_todo_id = len(get_user_todos(current_user["id"])) + 1
    new_todo = {
        "id": new_todo_id,
        "user_id": current_user["id"],
        **todo.dict(),
        "created_at": datetime.now(),
        "updated_at": datetime.now(),
    }
    created_todo = create_todo(new_todo)
    return created_todo


@app.get("/api/todos", response_model=List[Todo])
async def list_todos(
    current_user: dict = Depends(get_current_user),
    area: Optional[TodoArea] = None,
    deadline: Optional[date] = None,
    sort_by_deadline: bool = False,
):
    # Always include user_id in the query
    query = {"user_id": current_user["id"]}

    # Add area filter if provided
    if area:
        query["area"] = area.value

    # Add deadline filter if provided
    if deadline:
        deadline_date = datetime.combine(deadline, datetime.min.time())
        query["deadline"] = {
            "$gte": deadline_date,
            "$lt": datetime.combine(deadline, datetime.max.time()),
        }

    # Get todos from database with the query
    todos = get_user_todos(current_user["id"], query)

    # Sort by deadline if requested
    if sort_by_deadline:
        todos.sort(key=lambda x: x.get("deadline", datetime.max) or datetime.max)

    # Convert datetime back to date for response
    for todo in todos:
        if isinstance(todo.get("deadline"), datetime):
            todo["deadline"] = todo["deadline"].date()

    return todos


@app.get("/api/todos/search", response_model=List[Todo])
async def search_todos_endpoint(
    current_user: dict = Depends(get_current_user),
    query: str = None,
):
    """Search todos by title or description"""
    try:
        print(f"=== Search Request ===")
        print(f"Query: {query}")
        print(f"User ID: {current_user['id']}")

        # If no query provided, return all todos
        if not query:
            return await list_todos(current_user=current_user)

        # Build the search query
        search_query = {
            "user_id": current_user["id"],
            "$or": [
                {"title": {"$regex": query, "$options": "i"}},
                {"description": {"$regex": query, "$options": "i"}},
            ],
        }

        # Get todos from database with the query
        todos = get_user_todos(current_user["id"], search_query)

        # Convert datetime back to date for response
        for todo in todos:
            if isinstance(todo.get("deadline"), datetime):
                todo["deadline"] = todo["deadline"].date()

        print(f"=== Search Complete ===")
        print(f"Found {len(todos)} matching todos")
        return todos
    except Exception as e:
        print(f"Error in search endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to search todos: {str(e)}")


@app.get("/api/todos/{todo_id}", response_model=Todo)
async def get_todo_endpoint(
    todo_id: int, current_user: dict = Depends(get_current_user)
):
    todo = get_todo(todo_id, current_user["id"])
    if not todo:
        raise HTTPException(status_code=404, detail="Todo not found")
    # Convert datetime back to date for response
    if isinstance(todo.get("deadline"), datetime):
        todo["deadline"] = todo["deadline"].date()
    return todo


@app.put("/api/todos/{todo_id}", response_model=Todo)
async def update_todo_endpoint(
    todo_id: int,
    todo_update: TodoUpdate,
    current_user: dict = Depends(get_current_user),
):
    # First get the todo to ensure it belongs to the current user
    todo = get_todo(todo_id, current_user["id"])
    if not todo:
        raise HTTPException(status_code=404, detail="Todo not found")

    # Convert the update data to a dict, including the completed field
    update_data = todo_update.dict(exclude_unset=True)

    # Handle priority conversion if present
    if "priority" in update_data and update_data["priority"] is not None:
        update_data["priority"] = update_data["priority"].value

    # Ensure completed is a boolean
    if "completed" in update_data:
        update_data["completed"] = bool(update_data["completed"])

    update_data["updated_at"] = datetime.now()

    # Update the todo
    updated_todo = update_todo(todo_id, current_user["id"], update_data)
    if not updated_todo:
        raise HTTPException(status_code=404, detail="Todo not found")

    # Convert datetime back to date for response
    if isinstance(updated_todo.get("deadline"), datetime):
        updated_todo["deadline"] = updated_todo["deadline"].date()
    return updated_todo


@app.delete("/api/todos/{todo_id}", response_model=Todo)
async def delete_todo_endpoint(
    todo_id: int, current_user: dict = Depends(get_current_user)
):
    todo = get_todo(todo_id, current_user["id"])
    if not todo:
        raise HTTPException(status_code=404, detail="Todo not found")

    if not delete_todo(todo_id, current_user["id"]):
        raise HTTPException(status_code=404, detail="Todo not found")
    # Convert datetime back to date for response
    if isinstance(todo.get("deadline"), datetime):
        todo["deadline"] = todo["deadline"].date()
    return todo


@app.get("/api/todos/deadline/{deadline_date}", response_model=List[Todo])
async def get_todos_by_deadline_endpoint(
    deadline_date: date, current_user: dict = Depends(get_current_user)
):
    todos = get_todos_by_deadline(deadline_date.isoformat(), current_user["id"])
    # Convert datetime back to date for response
    for todo in todos:
        if isinstance(todo.get("deadline"), datetime):
            todo["deadline"] = todo["deadline"].date()
    return todos


@app.get("/api/todos/area/{area}", response_model=List[Todo])
async def get_todos_by_area_endpoint(
    area: TodoArea, current_user: dict = Depends(get_current_user)
):
    todos = get_todos_by_area(area.value, current_user["id"])
    # Convert datetime back to date for response
    for todo in todos:
        if isinstance(todo.get("deadline"), datetime):
            todo["deadline"] = todo["deadline"].date()
    return todos


@app.get("/api/users/me", response_model=User)
async def read_users_me(current_user: dict = Depends(get_current_user)):
    return current_user


@app.get("/api/test")
async def test_endpoint():
    """Test endpoint to verify server connectivity"""
    print("Test endpoint called")
    return {"message": "Server is working!"}
