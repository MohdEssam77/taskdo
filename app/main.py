from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from enum import IntEnum, Enum
from typing import List, Optional
from pydantic import BaseModel, Field, EmailStr
from datetime import datetime, date, timedelta
from passlib.context import CryptContext
from jose import JWTError, jwt
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Security configuration
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-for-development")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/token")

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
    description: str = Field(...)
    priority: Priority = Field(default=Priority.LOW)
    area: TodoArea = Field(...)
    deadline: date = Field(...)


class TodoCreate(BaseModel):
    title: str = Field(..., min_length=3, max_length=512)
    description: str = Field(...)
    priority: Priority = Field(default=Priority.LOW)
    area: TodoArea = Field(...)
    deadline: date = Field(...)


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
    priority: Optional[Priority] = Field(None)
    area: Optional[TodoArea] = Field(None)
    deadline: Optional[date] = Field(None)


# In-memory storage
users_db = []
todos_db = []


def get_user(username: str):
    for user in users_db:
        if user.username == username:
            return user
    return None


def authenticate_user(username: str, password: str):
    user = get_user(username)
    if not user:
        return False
    if not verify_password(password, user.hashed_password):
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

    db_user = UserInDB(
        id=len(users_db) + 1,
        email=user.email,
        username=user.username,
        hashed_password=get_password_hash(user.password),
    )
    users_db.append(db_user)
    return db_user


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
        data={"sub": user.username}, expires_delta=access_token_expires
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
async def create_todo(todo: TodoCreate, current_user: User = Depends(get_current_user)):
    new_todo_id = max([todo.id for todo in todos_db], default=0) + 1
    new_todo = Todo(
        id=new_todo_id,
        user_id=current_user.id,
        **todo.dict(),
        created_at=datetime.now(),
        updated_at=datetime.now(),
    )
    todos_db.append(new_todo)
    return new_todo


@app.get("/api/todos", response_model=List[Todo])
async def list_todos(current_user: User = Depends(get_current_user)):
    return [todo for todo in todos_db if todo.user_id == current_user.id]


@app.get("/api/todos/{todo_id}", response_model=Todo)
async def get_todo(todo_id: int, current_user: User = Depends(get_current_user)):
    for todo in todos_db:
        if todo.id == todo_id and todo.user_id == current_user.id:
            return todo
    raise HTTPException(status_code=404, detail="Todo not found")


@app.put("/api/todos/{todo_id}", response_model=Todo)
async def update_todo(
    todo_id: int,
    todo_update: TodoUpdate,
    current_user: User = Depends(get_current_user),
):
    for todo in todos_db:
        if todo.id == todo_id:
            if todo.user_id != current_user.id:
                raise HTTPException(
                    status_code=403, detail="Not authorized to update this todo"
                )
            update_data = todo_update.dict(exclude_unset=True)
            for key, value in update_data.items():
                setattr(todo, key, value)
            todo.updated_at = datetime.now()
            return todo
    raise HTTPException(status_code=404, detail="Todo not found")


@app.delete("/api/todos/{todo_id}", response_model=Todo)
async def delete_todo(todo_id: int, current_user: User = Depends(get_current_user)):
    for index, todo in enumerate(todos_db):
        if todo.id == todo_id:
            if todo.user_id != current_user.id:
                raise HTTPException(
                    status_code=403, detail="Not authorized to delete this todo"
                )
            return todos_db.pop(index)
    raise HTTPException(status_code=404, detail="Todo not found")


@app.get("/api/todos/deadline/{deadline_date}", response_model=List[Todo])
async def get_todos_by_deadline(
    deadline_date: date, current_user: User = Depends(get_current_user)
):
    return [
        todo
        for todo in todos_db
        if todo.deadline == deadline_date and todo.user_id == current_user.id
    ]


@app.get("/api/todos/area/{area}", response_model=List[Todo])
async def get_todos_by_area(
    area: TodoArea, current_user: User = Depends(get_current_user)
):
    return [
        todo
        for todo in todos_db
        if todo.area == area and todo.user_id == current_user.id
    ]
