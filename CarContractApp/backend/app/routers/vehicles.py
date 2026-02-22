"""
Vehicles Router
Handles VIN lookup and price estimation
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..database import get_db, Vehicle
from ..models.schemas import VINLookupResponse, PriceEstimateRequest, PriceEstimateResponse, PriceRecommendationResponse
from ..services.vin_service import vin_service, VINException
from ..services.price_service import price_service

router = APIRouter(prefix="/vehicles", tags=["Vehicles"])


@router.get("/vin/{vin}", response_model=VINLookupResponse)
async def lookup_vin(
    vin: str,
    db: Session = Depends(get_db)
):
    """
    Look up vehicle information by VIN
    
    Uses NHTSA API to decode VIN and get vehicle details including recalls
    """
    # Normalize VIN
    vin = vin.upper().strip()
    
    # Check cache in database first
    cached_vehicle = db.query(Vehicle).filter(Vehicle.vin == vin).first()
    if cached_vehicle:
        return VINLookupResponse(
            vin=cached_vehicle.vin,
            make=cached_vehicle.make,
            model=cached_vehicle.model,
            year=cached_vehicle.year,
            trim=cached_vehicle.trim,
            body_type=cached_vehicle.body_type,
            engine=cached_vehicle.engine,
            transmission=cached_vehicle.transmission,
            drivetrain=cached_vehicle.drivetrain,
            fuel_type=cached_vehicle.fuel_type,
            recalls=cached_vehicle.recalls,
            estimated_value=cached_vehicle.estimated_value,
            source="cache"
        )
    
    try:
        # Fetch from NHTSA API
        vehicle_info = await vin_service.get_full_vehicle_info(vin)
        
        # Save to database for caching
        db_vehicle = Vehicle(
            vin=vin,
            make=vehicle_info.get("make"),
            model=vehicle_info.get("model"),
            year=vehicle_info.get("year"),
            trim=vehicle_info.get("trim"),
            body_type=vehicle_info.get("body_type"),
            engine=vehicle_info.get("engine"),
            transmission=vehicle_info.get("transmission"),
            drivetrain=vehicle_info.get("drivetrain"),
            fuel_type=vehicle_info.get("fuel_type"),
            recalls=vehicle_info.get("recalls"),
            source="NHTSA"
        )
        
        db.add(db_vehicle)
        db.commit()
        db.refresh(db_vehicle)
        
        return VINLookupResponse(
            vin=vin,
            make=vehicle_info.get("make"),
            model=vehicle_info.get("model"),
            year=vehicle_info.get("year"),
            trim=vehicle_info.get("trim"),
            body_type=vehicle_info.get("body_type"),
            engine=vehicle_info.get("engine"),
            transmission=vehicle_info.get("transmission"),
            drivetrain=vehicle_info.get("drivetrain"),
            fuel_type=vehicle_info.get("fuel_type"),
            recalls=vehicle_info.get("recalls"),
            source="NHTSA"
        )
        
    except VINException as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.post("/price", response_model=PriceEstimateResponse)
async def estimate_price(
    request: PriceEstimateRequest
):
    """
    Estimate fair market value for a vehicle
    
    Based on make, model, year, mileage, and condition
    """
    try:
        estimate = await price_service.estimate_price(
            make=request.make,
            model=request.model,
            year=request.year,
            mileage=request.mileage,
            trim=request.trim,
            condition=request.condition
        )
        
        return PriceEstimateResponse(
            make=estimate["make"],
            model=estimate["model"],
            year=estimate["year"],
            estimated_value_low=estimate["estimated_value_low"],
            estimated_value_high=estimate["estimated_value_high"],
            estimated_value_avg=estimate["estimated_value_avg"],
            confidence=estimate["confidence"],
            source=estimate["source"],
            notes=estimate.get("notes")
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Price estimation failed: {str(e)}"
        )


@router.get("/vin/{vin}/price", response_model=PriceEstimateResponse)
async def get_price_by_vin(
    vin: str,
    mileage: int = None,
    condition: str = "good",
    db: Session = Depends(get_db)
):
    """
    Look up VIN and estimate price in one call
    """
    # First look up the VIN
    vin = vin.upper().strip()
    
    try:
        vehicle_info = await vin_service.get_full_vehicle_info(vin)
    except VINException as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    
    make = vehicle_info.get("make")
    model = vehicle_info.get("model")
    year = vehicle_info.get("year")
    
    if not all([make, model, year]):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not determine vehicle make, model, or year from VIN"
        )
    
    # Estimate price
    estimate = await price_service.estimate_price(
        make=make,
        model=model,
        year=year,
        mileage=mileage,
        trim=vehicle_info.get("trim"),
        condition=condition
    )
    
    return PriceEstimateResponse(
        make=estimate["make"],
        model=estimate["model"],
        year=estimate["year"],
        estimated_value_low=estimate["estimated_value_low"],
        estimated_value_high=estimate["estimated_value_high"],
        estimated_value_avg=estimate["estimated_value_avg"],
        confidence=estimate["confidence"],
        source=estimate["source"],
        notes=estimate.get("notes")
    )


@router.get("/vin/{vin}/price-recommendation", response_model=PriceRecommendationResponse)
async def get_price_recommendation(
    vin: str,
    mileage: int = None,
    condition: str = "good",
    db: Session = Depends(get_db)
):
    """
    Get a structured price recommendation for a vehicle by VIN (Gap 3).
    
    Returns fair price range, MSRP estimate, methodology, and confidence.
    """
    vin = vin.upper().strip()
    
    try:
        vehicle_info = await vin_service.get_full_vehicle_info(vin)
    except VINException as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    
    make = vehicle_info.get("make")
    model = vehicle_info.get("model")
    year = vehicle_info.get("year")
    trim = vehicle_info.get("trim")
    
    if not all([make, model, year]):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not determine vehicle make, model, or year from VIN"
        )
    
    recommendation = await price_service.generate_recommendation(
        make=make,
        model=model,
        year=year,
        mileage=mileage,
        trim=trim,
        condition=condition
    )
    
    return PriceRecommendationResponse(**recommendation)

