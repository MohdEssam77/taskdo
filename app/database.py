from pymongo import MongoClient
from pymongo.collection import Collection
from pymongo.database import Database
from typing import Optional, List, Dict, Any
import os
from dotenv import load_dotenv
from datetime import datetime, date
import re

load_dotenv()

# MongoDB connection string
MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017/")
DB_NAME = "taskdo"

print(f"Attempting to connect to MongoDB at: {MONGODB_URL}")  # Debug print

# Create MongoDB client
try:
    client = MongoClient(MONGODB_URL)
    # Test the connection
    client.server_info()
    print("Successfully connected to MongoDB!")  # Debug print
except Exception as e:
    print(f"Failed to connect to MongoDB: {str(e)}")  # Debug print
    raise

db: Database = client[DB_NAME]

# Collections
users_collection: Collection = db["users"]
todos_collection: Collection = db["todos"]

print(f"Using database: {DB_NAME}")  # Debug print
print(f"Collections: {db.list_collection_names()}")  # Debug print


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
    # Ensure completed is a boolean
    if "completed" in converted_data:
        converted_data["completed"] = bool(converted_data["completed"])
    result = todos_collection.insert_one(converted_data)
    converted_data["_id"] = str(result.inserted_id)
    return converted_data


def update_todo(todo_id: int, user_id: int, update_data: dict) -> Optional[dict]:
    """Update a todo"""
    # Convert date to datetime before updating
    converted_data = convert_date_to_datetime(update_data)

    # First verify the todo exists and belongs to the user
    existing_todo = todos_collection.find_one({"id": todo_id, "user_id": user_id})
    if not existing_todo:
        return None

    # Merge the existing todo with the update data to preserve fields not included in the update
    merged_data = existing_todo.copy()
    merged_data.update(converted_data)

    # Update the todo with the merged data
    result = todos_collection.update_one(
        {"id": todo_id, "user_id": user_id}, {"$set": converted_data}
    )

    # Return the updated todo
    if result.modified_count > 0:
        return todos_collection.find_one({"id": todo_id, "user_id": user_id})
    return None


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


def check_user_todos(user_id: int) -> bool:
    """Check if a user has any todos"""
    try:
        count = todos_collection.count_documents({"user_id": user_id})
        print(f"User {user_id} has {count} todos")
        return count > 0
    except Exception as e:
        print(f"Error checking user todos: {str(e)}")
        return False


def search_todos(query: str, user_id: int) -> List[dict]:
    """Search todos by title or description"""
    try:
        print(f"=== Database Search ===")
        print(f"Query: {query}")
        print(f"User ID: {user_id}")

        # Build the search query
        search_query = {
            "user_id": user_id,
            "$or": [
                {"title": {"$regex": query, "$options": "i"}},
                {"description": {"$regex": query, "$options": "i"}},
            ],
        }

        # Execute the query
        result = list(todos_collection.find(search_query))
        print(f"Found {len(result)} matching todos")

        if not result:
            print("No todos found matching the search criteria")
            return []

        print(f"=== Database Search Complete ===")
        return result
    except Exception as e:
        print(f"Error in search_todos: {str(e)}")
        raise Exception(f"Failed to search todos: {str(e)}")
