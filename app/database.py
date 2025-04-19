from pymongo import MongoClient
from pymongo.collection import Collection
from pymongo.database import Database
from typing import Optional, List, Dict, Any
import os
from dotenv import load_dotenv
from datetime import datetime, date

load_dotenv()

# MongoDB connection string
MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017/")
DB_NAME = "taskdo"

# Create MongoDB client
client = MongoClient(MONGODB_URL)
db: Database = client[DB_NAME]

# Collections
users_collection: Collection = db["users"]
todos_collection: Collection = db["todos"]


def convert_date_to_datetime(data: dict) -> dict:
    """Convert date objects to datetime objects for MongoDB storage"""
    converted = data.copy()
    if "deadline" in converted and isinstance(converted["deadline"], date):
        converted["deadline"] = datetime.combine(
            converted["deadline"], datetime.min.time()
        )
    return converted


def get_user(username: str) -> Optional[dict]:
    """Get user by username"""
    return users_collection.find_one({"username": username})


def create_user(user_data: dict) -> dict:
    """Create a new user"""
    result = users_collection.insert_one(user_data)
    user_data["_id"] = str(result.inserted_id)
    return user_data


def get_todo(todo_id: int, user_id: int) -> Optional[dict]:
    """Get todo by id and user_id"""
    return todos_collection.find_one({"id": todo_id, "user_id": user_id})


def get_user_todos(user_id: int, query: Optional[Dict[str, Any]] = None) -> List[dict]:
    """Get all todos for a user with optional filtering"""
    base_query = {"user_id": user_id}
    if query:
        base_query.update(query)

    # Convert any date strings in the query to datetime objects
    if "deadline" in base_query and isinstance(base_query["deadline"], dict):
        if "$gte" in base_query["deadline"] and isinstance(
            base_query["deadline"]["$gte"], str
        ):
            base_query["deadline"]["$gte"] = datetime.fromisoformat(
                base_query["deadline"]["$gte"]
            )
        if "$lt" in base_query["deadline"] and isinstance(
            base_query["deadline"]["$lt"], str
        ):
            base_query["deadline"]["$lt"] = datetime.fromisoformat(
                base_query["deadline"]["$lt"]
            )

    print(f"Executing query: {base_query}")  # Debug print
    todos = list(todos_collection.find(base_query))
    print(f"Found {len(todos)} todos")  # Debug print
    return todos


def create_todo(todo_data: dict) -> dict:
    """Create a new todo"""
    # Convert date to datetime before storing
    converted_data = convert_date_to_datetime(todo_data)
    result = todos_collection.insert_one(converted_data)
    converted_data["_id"] = str(result.inserted_id)
    return converted_data


def update_todo(todo_id: int, user_id: int, update_data: dict) -> Optional[dict]:
    """Update a todo"""
    # Convert date to datetime before updating
    converted_data = convert_date_to_datetime(update_data)
    result = todos_collection.find_one_and_update(
        {"id": todo_id, "user_id": user_id},
        {"$set": converted_data},
        return_document=True,
    )
    return result


def delete_todo(todo_id: int, user_id: int) -> bool:
    """Delete a todo"""
    result = todos_collection.delete_one({"id": todo_id, "user_id": user_id})
    return result.deleted_count > 0


def get_todos_by_deadline(deadline: str, user_id: int) -> list:
    """Get todos by deadline"""
    # Convert string date to datetime for query
    deadline_date = datetime.strptime(deadline, "%Y-%m-%d")
    return list(
        todos_collection.find(
            {
                "deadline": {
                    "$gte": datetime.combine(deadline_date, datetime.min.time()),
                    "$lt": datetime.combine(deadline_date, datetime.max.time()),
                },
                "user_id": user_id,
            }
        )
    )


def get_todos_by_area(area: str, user_id: int) -> list:
    """Get todos by area"""
    return list(todos_collection.find({"area": area, "user_id": user_id}))
