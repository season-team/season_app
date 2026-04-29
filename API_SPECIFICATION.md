# Travel Bag Management App - API Specification

This document outlines all the required APIs for the Travel Bag Management mobile application based on the UI designs.

## Table of Contents
1. [Travel Bag Management](#travel-bag-management)
2. [Item Management](#item-management)
3. [Reminder Management](#reminder-management)
4. [AI Suggestions](#ai-suggestions)
5. [Packing Tips](#packing-tips)

---

## Travel Bag Management

### 1. Get Travel Bag Details
**Endpoint:** `GET /api/travel-bag/details`  
**Description:** Retrieve details of the user's main travel bag including current weight, maximum weight, and items list.

**Response:**
```json
{
  "success": true,
  "data": {
    "bag_id": "string",
    "bag_name": "شنطة الشحن الرئيسية",
    "bag_type": "main_cargo",
    "current_weight": 0.0,
    "max_weight": 23.0,
    "weight_unit": "kg",
    "weight_percentage": 0.0,
    "items": [
      {
        "item_id": "string",
        "name": "string",
        "category": "string",
        "category_arabic": "string",
        "quantity": 1,
        "weight_per_item": 0.5,
        "total_weight": 0.5,
        "icon": "string"
      }
    ],
    "is_empty": true
  }
}
```

### 2. Update Maximum Weight
**Endpoint:** `PUT /api/travel-bag/max-weight`  
**Description:** Update the maximum allowed weight for the travel bag.

**Request Body:**
```json
{
  "max_weight": 23.0,
  "weight_unit": "kg"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Maximum weight updated successfully",
  "data": {
    "max_weight": 23.0,
    "current_weight": 0.0,
    "weight_percentage": 0.0
  }
}
```

### 3. Add Item to Travel Bag
**Endpoint:** `POST /api/travel-bag/add-item`  
**Description:** Add a new item (or increase quantity of existing item) to the travel bag.

**Request Body:**
```json
{
  "item_id": "string",
  "quantity": 1,
  "custom_weight": null
}
```

**Response:**
```json
{
  "success": true,
  "message": "Item added successfully",
  "data": {
    "item_added": {
      "item_id": "string",
      "name": "string",
      "category": "string",
      "quantity": 1,
      "weight_per_item": 0.5,
      "total_weight": 0.5
    },
    "updated_bag": {
      "current_weight": 0.5,
      "max_weight": 23.0,
      "weight_percentage": 2.17,
      "total_items": 1
    }
  }
}
```

### 4. Remove Item from Travel Bag
**Endpoint:** `DELETE /api/travel-bag/items/{item_id}`  
**Description:** Remove an item from the travel bag or decrease its quantity.

**Request Body (Optional):**
```json
{
  "quantity": 1
}
```

**Response:**
```json
{
  "success": true,
  "message": "Item removed successfully",
  "data": {
    "updated_bag": {
      "current_weight": 0.0,
      "max_weight": 23.0,
      "weight_percentage": 0.0,
      "total_items": 0
    }
  }
}
```

### 5. Get Travel Bag Items
**Endpoint:** `GET /api/travel-bag/items`  
**Description:** Get list of all items currently in the travel bag.

**Response:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "item_id": "string",
        "name": "string",
        "name_arabic": "string",
        "category": "string",
        "category_arabic": "string",
        "quantity": 1,
        "weight_per_item": 0.5,
        "total_weight": 0.5,
        "icon": "string"
      }
    ],
    "total_weight": 1.7,
    "total_items": 5
  }
}
```

---

## Item Management

### 6. Get All Categories
**Endpoint:** `GET /api/items/categories`  
**Description:** Retrieve list of all available item categories.

**Response:**
```json
{
  "success": true,
  "data": {
    "categories": [
      {
        "category_id": "string",
        "name": "electronics",
        "name_arabic": "إلكترونيات",
        "icon": "string",
        "icon_color": "string"
      },
      {
        "category_id": "string",
        "name": "clothing",
        "name_arabic": "ملابس",
        "icon": "string",
        "icon_color": "string"
      },
      {
        "category_id": "string",
        "name": "personal_items",
        "name_arabic": "أغراض شخصية",
        "icon": "string",
        "icon_color": "string"
      }
    ]
  }
}
```

**Categories to Include:**
- Electronics (إلكترونيات)
- Clothing (ملابس)
- Personal Items (أغراض شخصية)

### 7. Get Items by Category
**Endpoint:** `GET /api/items?category_id={category_id}`  
**Description:** Retrieve list of all predefined items for a specific category.

**Query Parameters:**
- `category_id` (required): The category ID

**Response:**
```json
{
  "success": true,
  "data": {
    "category": {
      "category_id": "string",
      "name": "electronics",
      "name_arabic": "إلكترونيات"
    },
    "items": [
      {
        "item_id": "string",
        "name": "laptop",
        "name_arabic": "حاسوب محمول",
        "default_weight": 2.0,
        "weight_unit": "kg",
        "category_id": "string",
        "icon": "string"
      },
      {
        "item_id": "string",
        "name": "laptop_charger",
        "name_arabic": "شاحن حاسوب",
        "default_weight": 0.3,
        "weight_unit": "kg",
        "category_id": "string",
        "icon": "string"
      },
      {
        "item_id": "string",
        "name": "mobile_phone",
        "name_arabic": "هاتف محمول",
        "default_weight": 0.2,
        "weight_unit": "kg",
        "category_id": "string",
        "icon": "string"
      },
      {
        "item_id": "string",
        "name": "phone_charger",
        "name_arabic": "شاحن هاتف",
        "default_weight": 0.1,
        "weight_unit": "kg",
        "category_id": "string",
        "icon": "string"
      },
      {
        "item_id": "string",
        "name": "headphones",
        "name_arabic": "سماعات",
        "default_weight": 0.1,
        "weight_unit": "kg",
        "category_id": "string",
        "icon": "string"
      },
      {
        "item_id": "string",
        "name": "power_bank",
        "name_arabic": "باور بانك",
        "default_weight": 0.3,
        "weight_unit": "kg",
        "category_id": "string",
        "icon": "string"
      },
      {
        "item_id": "string",
        "name": "camera",
        "name_arabic": "كاميرا",
        "default_weight": 0.6,
        "weight_unit": "kg",
        "category_id": "string",
        "icon": "string"
      },
      {
        "item_id": "string",
        "name": "tablet",
        "name_arabic": "تابلت",
        "default_weight": 0.5,
        "weight_unit": "kg",
        "category_id": "string",
        "icon": "string"
      },
      {
        "item_id": "string",
        "name": "usb_cable",
        "name_arabic": "كيبل USB",
        "default_weight": 0.05,
        "weight_unit": "kg",
        "category_id": "string",
        "icon": "string"
      },
      {
        "item_id": "string",
        "name": "power_adapter",
        "name_arabic": "محول كهرباء",
        "default_weight": 0.2,
        "weight_unit": "kg",
        "category_id": "string",
        "icon": "string"
      }
    ]
  }
}
```

**Notes:**
- Electronics category items shown in UI should all be included with their Arabic names and weights
- Similar items should exist for Clothing and Personal Items categories

### 8. Get Single Item Details
**Endpoint:** `GET /api/items/{item_id}`  
**Description:** Get detailed information about a specific item.

**Response:**
```json
{
  "success": true,
  "data": {
    "item_id": "string",
    "name": "string",
    "name_arabic": "string",
    "default_weight": 0.5,
    "weight_unit": "kg",
    "category": {
      "category_id": "string",
      "name": "string",
      "name_arabic": "string"
    },
    "icon": "string",
    "description": "string",
    "description_arabic": "string"
  }
}
```

---

## Reminder Management

### 9. Get All Reminders
**Endpoint:** `GET /api/reminders`  
**Description:** Retrieve all reminders for the authenticated user.

**Query Parameters (Optional):**
- `status`: Filter by status (active, completed, cancelled)
- `from_date`: Filter reminders from this date
- `to_date`: Filter reminders until this date

**Response:**
```json
{
  "success": true,
  "data": {
    "reminders": [
      {
        "reminder_id": "string",
        "title": "string",
        "title_arabic": "string",
        "date": "2025-10-06",
        "time": "12:00:00",
        "timezone": "UTC",
        "recurrence": "once",
        "recurrence_arabic": "مرة واحدة",
        "notes": "string",
        "notes_arabic": "string",
        "status": "active",
        "created_at": "2025-01-01T00:00:00Z",
        "updated_at": "2025-01-01T00:00:00Z"
      }
    ],
    "active_count": 0,
    "total_count": 0
  }
}
```

**Recurrence Options:**
- `once` - مرة واحدة (Once)
- `daily` - يومي (Daily)
- `weekly` - أسبوعي (Weekly)
- `monthly` - شهري (Monthly)

### 10. Create New Reminder
**Endpoint:** `POST /api/reminders`  
**Description:** Create a new reminder for the user.

**Request Body:**
```json
{
  "title": "string",
  "date": "2025-10-06",
  "time": "12:00",
  "recurrence": "once",
  "notes": "string (optional)"
}
```

**Validation Rules:**
- `title`: Required, string, max 200 characters
- `date`: Required, valid date format (YYYY-MM-DD)
- `time`: Required, valid time format (HH:MM)
- `recurrence`: Required, one of: "once", "daily", "weekly", "monthly"
- `notes`: Optional, string, max 1000 characters

**Response:**
```json
{
  "success": true,
  "message": "Reminder created successfully",
  "data": {
    "reminder_id": "string",
    "title": "string",
    "date": "2025-10-06",
    "time": "12:00:00",
    "recurrence": "once",
    "notes": "string",
    "status": "active",
    "created_at": "2025-01-01T00:00:00Z"
  }
}
```

### 11. Update Reminder
**Endpoint:** `PUT /api/reminders/{reminder_id}`  
**Description:** Update an existing reminder.

**Request Body:**
```json
{
  "title": "string (optional)",
  "date": "2025-10-06 (optional)",
  "time": "12:00 (optional)",
  "recurrence": "once (optional)",
  "notes": "string (optional)",
  "status": "active (optional)"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Reminder updated successfully",
  "data": {
    "reminder_id": "string",
    "title": "string",
    "date": "2025-10-06",
    "time": "12:00:00",
    "recurrence": "once",
    "notes": "string",
    "status": "active",
    "updated_at": "2025-01-01T00:00:00Z"
  }
}
```

### 12. Delete Reminder
**Endpoint:** `DELETE /api/reminders/{reminder_id}`  
**Description:** Delete a reminder.

**Response:**
```json
{
  "success": true,
  "message": "Reminder deleted successfully"
}
```

---

## AI Suggestions

### 13. Get AI Suggestions
**Endpoint:** `GET /api/ai/suggestions`  
**Description:** Get AI-powered packing suggestions based on destination and current bag contents.

**Query Parameters:**
- `destination` (optional): Destination country/city (e.g., "Egypt", "مصر")
- `destination_id` (optional): Destination ID if using predefined destinations
- `include_current_items` (optional, default: true): Whether to consider items already in bag

**Response:**
```json
{
  "success": true,
  "data": {
    "destination": {
      "name": "Egypt",
      "name_arabic": "مصر"
    },
    "suggestions": [
      {
        "item_id": "string",
        "name": "sunglasses",
        "name_arabic": "نظارة شمسية",
        "weight": 0.1,
        "weight_unit": "kg",
        "category": "personal_items",
        "category_arabic": "أغراض شخصية",
        "description": "Essential for visiting pyramids and landmarks",
        "description_arabic": "أساسي لزيارة الأهرامات والمعالم",
        "reason": "string",
        "priority": "high",
        "icon": "string",
        "is_in_bag": false
      },
      {
        "item_id": "string",
        "name": "pants",
        "name_arabic": "بنطلون",
        "weight": 0.3,
        "weight_unit": "kg",
        "category": "clothing",
        "category_arabic": "ملابس",
        "description": "For sun protection",
        "description_arabic": "للحماية من الشمس",
        "reason": "string",
        "priority": "medium",
        "icon": "string",
        "is_in_bag": false
      },
      {
        "item_id": "string",
        "name": "sports_shoes",
        "name_arabic": "حذاء رياضي",
        "weight": 0.4,
        "weight_unit": "kg",
        "category": "clothing",
        "category_arabic": "ملابس",
        "description": "For walking in archaeological sites",
        "description_arabic": "للمشي في المواقع الأثرية",
        "reason": "string",
        "priority": "medium",
        "icon": "string",
        "is_in_bag": false
      },
      {
        "item_id": "string",
        "name": "camera",
        "name_arabic": "كاميرا",
        "weight": 0.6,
        "weight_unit": "kg",
        "category": "electronics",
        "category_arabic": "الكترونيات",
        "description": "To document tourist landmarks",
        "description_arabic": "لتوثيق المعالم السياحية",
        "reason": "string",
        "priority": "high",
        "icon": "string",
        "is_in_bag": false
      },
      {
        "item_id": "string",
        "name": "phone_charger",
        "name_arabic": "شاحن هاتف",
        "weight": 0.1,
        "weight_unit": "kg",
        "category": "electronics",
        "category_arabic": "الكترونيات",
        "description": "Essential to stay connected",
        "description_arabic": "ضروري للبقاء على اتصال",
        "reason": "string",
        "priority": "high",
        "icon": "string",
        "is_in_bag": false
      },
      {
        "item_id": "string",
        "name": "toothbrush",
        "name_arabic": "فرشاة أسنان",
        "weight": 0.05,
        "weight_unit": "kg",
        "category": "personal_items",
        "category_arabic": "أغراض شخصية",
        "description": "One of the daily essentials",
        "description_arabic": "من الأساسيات اليومية",
        "reason": "string",
        "priority": "high",
        "icon": "string",
        "is_in_bag": false
      }
    ],
    "total_suggestions": 6
  }
}
```

### 14. Add Suggested Item to Bag
**Endpoint:** `POST /api/ai/suggestions/add-item`  
**Description:** Add a suggested item directly to the bag from AI suggestions screen.

**Request Body:**
```json
{
  "item_id": "string",
  "quantity": 1
}
```

**Response:**
```json
{
  "success": true,
  "message": "Item added successfully",
  "data": {
    "item_added": {
      "item_id": "string",
      "name_arabic": "string",
      "quantity": 1,
      "weight": 0.1
    },
    "updated_bag": {
      "current_weight": 1.7,
      "max_weight": 23.0,
      "weight_percentage": 7.39
    }
  }
}
```

---

## Packing Tips

### 15. Get Packing Tips
**Endpoint:** `GET /api/packing-tips`  
**Description:** Retrieve list of packing tips to display to users.

**Query Parameters (Optional):**
- `limit`: Number of tips to return (default: 10)

**Response:**
```json
{
  "success": true,
  "data": {
    "tips": [
      {
        "tip_id": "string",
        "text": "Put heavy items at the bottom",
        "text_arabic": "ضع الأشياء الثقيلة في الأسفل",
        "category": "organization",
        "priority": 1
      },
      {
        "tip_id": "string",
        "text": "Wrap clothes instead of folding to save space",
        "text_arabic": "لف الملابس بدلاً من طيها لتوفير المساحة",
        "category": "space_saving",
        "priority": 2
      },
      {
        "tip_id": "string",
        "text": "Keep valuables in hand luggage",
        "text_arabic": "احتفظ بالأشياء القيمة في حقيبة اليد",
        "category": "security",
        "priority": 3
      },
      {
        "tip_id": "string",
        "text": "Check the allowed weight from the airline company",
        "text_arabic": "تأكد من الوزن المسموح به من شركة الطيران",
        "category": "weight",
        "priority": 4
      }
    ],
    "total_tips": 4
  }
}
```

---

## Error Responses

All endpoints should return standardized error responses:

**400 Bad Request:**
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": [
      {
        "field": "date",
        "message": "Invalid date format"
      }
    ]
  }
}
```

**401 Unauthorized:**
```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Authentication required"
  }
}
```

**404 Not Found:**
```json
{
  "success": false,
  "error": {
    "code": "NOT_FOUND",
    "message": "Resource not found"
  }
}
```

**500 Internal Server Error:**
```json
{
  "success": false,
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "An internal error occurred"
  }
}
```

---

## Authentication

All endpoints require authentication. Include authentication token in the request headers:

```
Authorization: Bearer {token}
```

---

## Notes for Backend Developer

1. **Language Support:**
   - All endpoints should support both English and Arabic text
   - Response objects should include both `name` and `name_arabic` fields where applicable
   - Consider using locale parameter if needed

2. **Weight Calculations:**
   - Weight should be calculated automatically when items are added
   - Total weight = sum of (item_weight * quantity) for all items
   - Weight percentage = (current_weight / max_weight) * 100

3. **Real-time Updates:**
   - When an item is added/removed, the bag weight should be updated immediately
   - Consider implementing WebSocket or polling for real-time weight updates if needed

4. **Date/Time Handling:**
   - Use ISO 8601 format for dates and times
   - Handle timezone conversions appropriately
   - Store reminders with timezone information

5. **AI Suggestions Algorithm:**
   - Should consider destination climate, activities, and culture
   - Should check if items are already in the bag
   - Should prioritize essential items
   - Should provide reasons for suggestions

6. **Data Validation:**
   - Validate all input fields on the backend
   - Enforce weight limits (prevent adding items if total weight exceeds max_weight)
   - Validate date ranges for reminders
   - Ensure quantity is positive integer

7. **Default Values:**
   - Default max_weight: 23 kg (as shown in UI)
   - Default weight unit: kg
   - Default quantity when adding item: 1

---

## Additional Considerations

- **User Context:** All endpoints operate within the context of the authenticated user
- **Bag Types:** Consider supporting multiple bags per user (main cargo bag, hand luggage, etc.)
- **Item Images/Icons:** Store icon URLs or icon identifiers for frontend display
- **Notification System:** Reminders should trigger push notifications at the specified time
- **Analytics:** Consider logging item additions, suggestions used, etc. for future improvements

---

**Last Updated:** January 2025  
**Version:** 1.0.0
