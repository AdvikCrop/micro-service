from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from contextlib import asynccontextmanager
from typing import List

from .database import engine, get_db, Base
from .models import Order, OrderCreate, OrderStatus
from .routers import health

Base.metadata.create_all(bind=engine)

@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    Base.metadata.create_all(bind=engine)

app = FastAPI(title="Order Service", version="1.0.0", lifespan=lifespan)

app.include_router(health.router)

@app.post("/api/v1/orders", response_model=Order)
def create_order(order: OrderCreate, db: Session = Depends(get_db)):
    """Create a new order."""
    db_order = Order(
        user_id=order.user_id,
        product_name=order.product_name,
        quantity=order.quantity,
        price=order.price,
        status=OrderStatus.PENDING
    )
    db.add(db_order)
    db.commit()
    db.refresh(db_order)
    return db_order

@app.get("/api/v1/orders/{order_id}", response_model=Order)
def get_order(order_id: int, db: Session = Depends(get_db)):
    """Get order by ID."""
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return order

@app.get("/api/v1/orders")
def list_orders(db: Session = Depends(get_db)):
    """List all orders."""
    return db.query(Order).all()

@app.get("/api/v1/orders/user/{user_id}")
def list_user_orders(user_id: int, db: Session = Depends(get_db)):
    """List orders for a specific user."""
    return db.query(Order).filter(Order.user_id == user_id).all()

@app.patch("/api/v1/orders/{order_id}/status")
def update_order_status(order_id: int, status: OrderStatus, db: Session = Depends(get_db)):
    """Update order status."""
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    order.status = status
    db.commit()
    db.refresh(order)
    return order
