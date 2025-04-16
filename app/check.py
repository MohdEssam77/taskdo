from fastapi import FastAPI,HTTPException
from enum import IntEnum
from typing import List,Optional
from pydantic import BaseModel,Field
api = FastAPI()

class Priority(IntEnum):
  LOW = 3
  MEDIUM = 2
  HIGH = 1


class TodoBase(BaseModel):
  todo_name: str = Field(...,min_length = 3,max_length=512,description = 'Name of the Todo')
  todo_description:str = Field(...,description='description of the todo')
  priority: Priority = Field(default=Priority.Low,description='Priority of the todo')

class todoCreate(TodoBase):
  pass



class Todo(TodoBase):
    todo_id:int = Field(...,description='Unique identifier of the todo')



class TodoUpdate(BaseModel):
    todo_name: Optional[str] = Field(None,min_length = 3,max_length=512,description = 'Name of the Todo')
  todo_description:Optional[str] = Field(None,description='description of the todo')
  priority: Optional[Priority] = Field(None,description='Priority of the todo')






all_todos = [
        Todo(todo_id=1,todo_name="Clean House",todo_description="Cleaning the hourse",priority=Priority.HIGH),
        Todo(todo_id=2,todo_name="sec Clean House",todo_description="sec Cleaning the hourse",priority=Priority.MEDIUM),
        Todo(todo_id=3,todo_name="thri Clean House",todo_description="thir Cleaning the hourse",priority=Priority.LOW),
        Todo(todo_id=4,todo_name="four Clean House",todo_description="four  Cleaning the hourse",priority=Priority.HIGH),
        Todo(todo_id=5,todo_name="fiv Clean House",todo_description="five Cleaning the hourse",priority=Priority.MEDIUM),
        Todo(todo_id=6,todo_name="sex Clean House",todo_description="sex Cleaning the hourse",priority=Priority.LOW),
        Todo(todo_id=7,todo_name="sev Clean House",todo_description="sev Cleaning the hourse",priority=Priority.HIGH),

]

 



@api.get('/todos/{todo_id}',response_model=Todo)
def get_todo(todo_id: int):
  for todo in all_todos:
    if todo.todo_id == todo_id:
      return todo


  raise HTTPException(status_code=404,detail='Todo not found')

@api.get('/todos',response_model=List[Todo])
def get_todos(first_n:int = None):
  if first_n:
    return all_todos[:first_n]
  else:
    return all_todos


@api.post('/todos',response_model=Todo)
def create_todo(todo: todoCreate):
  new_todo_id = max(todo.todo_id for todo in all_todos) +1

  new_todo = Todo(todo_id = new_todo_id,todo_name=todo.todo_name,todo_description=todo.todo_description,priority=todo.priority)

  all_todos.append(new_todo)
  
  return new_todo



@api.put('/todos/{todo_id}'response_model=Todo)
def update_todo(todo_id:int,updated_todo:TodoUpdate):
  for todo in all_todos:
    if todo.todo_id = todo_id:
        if updated_todo.todo_name is not None:
            todo.todo_name = update_todo.todo_name
        if updated_todo.todo_description is not None:
            todo.todo_description = update_todo.todo_description
        if updated_todo.priority is not None:
            todo.priority =update_todo.priority
      

      return todo
  raise HTTPException(status_code=404,detail='Todo not found')


@api.delete('/todos/{todo_id}',response_model=Todo)
def delete_todo(todo_id: int):
  for index,todo in enumerate(all_todos):
    if todo.todo_id == todo_id:
      deleted_todo = all_todos.pop(index)
      return deleted_todo
  raise HTTPException(status_code=404,detail='Todo not found')




