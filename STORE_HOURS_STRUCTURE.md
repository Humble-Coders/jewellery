# Store Hours - Updated Firebase Structure

## Firebase Collection: `store_info`

### Document: `store_hours_closed`

```json
{
  "monday": {
    "is_closed": false,
    "opening_time": "10:00",
    "closing_time": "18:00"
  },
  "tuesday": {
    "is_closed": false,
    "opening_time": "10:00",
    "closing_time": "18:00"
  },
  "wednesday": {
    "is_closed": false,
    "opening_time": "10:00",
    "closing_time": "18:00"
  },
  "thursday": {
    "is_closed": false,
    "opening_time": "10:00",
    "closing_time": "18:00"
  },
  "friday": {
    "is_closed": true,
    "opening_time": null,
    "closing_time": null
  },
  "saturday": {
    "is_closed": true,
    "opening_time": null,
    "closing_time": null
  },
  "sunday": {
    "is_closed": false,
    "opening_time": "11:00",
    "closing_time": "17:00"
  }
}
```

## Field Structure

### Each Day Object
- `is_closed` (boolean): `true` if store is closed that day, `false` if open
- `opening_time` (string | null): Opening time in 24-hour format "HH:mm" (e.g., "10:00" for 10 AM)
- `closing_time` (string | null): Closing time in 24-hour format "HH:mm" (e.g., "18:00" for 6 PM)

**Note**: If `is_closed: true`, set `opening_time` and `closing_time` to `null`

## Time Format

Use 24-hour format:
- `"09:00"` = 9:00 AM
- `"10:30"` = 10:30 AM
- `"13:00"` = 1:00 PM
- `"18:00"` = 6:00 PM
- `"21:30"` = 9:30 PM

## UI Display Format

The app will automatically convert to 12-hour format for display:
- `"10:00"` displays as "10:00 AM - 6:00 PM"
- Store automatically checks if current time is between opening and closing

## Example Scenarios

### Open All Week (Same Hours)
```json
{
  "monday": { "is_closed": false, "opening_time": "09:00", "closing_time": "21:00" },
  "tuesday": { "is_closed": false, "opening_time": "09:00", "closing_time": "21:00" },
  "wednesday": { "is_closed": false, "opening_time": "09:00", "closing_time": "21:00" },
  "thursday": { "is_closed": false, "opening_time": "09:00", "closing_time": "21:00" },
  "friday": { "is_closed": false, "opening_time": "09:00", "closing_time": "21:00" },
  "saturday": { "is_closed": false, "opening_time": "09:00", "closing_time": "21:00" },
  "sunday": { "is_closed": false, "opening_time": "09:00", "closing_time": "21:00" }
}
```

### Closed on Weekends
```json
{
  "monday": { "is_closed": false, "opening_time": "10:00", "closing_time": "18:00" },
  "tuesday": { "is_closed": false, "opening_time": "10:00", "closing_time": "18:00" },
  "wednesday": { "is_closed": false, "opening_time": "10:00", "closing_time": "18:00" },
  "thursday": { "is_closed": false, "opening_time": "10:00", "closing_time": "18:00" },
  "friday": { "is_closed": false, "opening_time": "10:00", "closing_time": "18:00" },
  "saturday": { "is_closed": true, "opening_time": null, "closing_time": null },
  "sunday": { "is_closed": true, "opening_time": null, "closing_time": null }
}
```

### Different Hours on Different Days
```json
{
  "monday": { "is_closed": false, "opening_time": "09:00", "closing_time": "17:00" },
  "tuesday": { "is_closed": false, "opening_time": "09:00", "closing_time": "17:00" },
  "wednesday": { "is_closed": false, "opening_time": "09:00", "closing_time": "17:00" },
  "thursday": { "is_closed": false, "opening_time": "09:00", "closing_time": "20:00" },
  "friday": { "is_closed": false, "opening_time": "09:00", "closing_time": "20:00" },
  "saturday": { "is_closed": false, "opening_time": "10:00", "closing_time": "18:00" },
  "sunday": { "is_closed": false, "opening_time": "11:00", "closing_time": "16:00" }
}
```

## How the App Uses This Data

1. **Current Status**: Compares current time with today's opening/closing times
2. **Open/Closed Badge**: Shows green "OPEN" or red "CLOSED" based on current time
3. **Today Section**: Displays today's hours prominently
4. **Weekly Schedule**: Shows all days with their respective hours

## Migration from Old Structure

If you have the old boolean structure:
```json
{
  "monday": true,  // true meant closed
  "tuesday": false // false meant open
}
```

Replace with:
```json
{
  "monday": {
    "is_closed": true,
    "opening_time": null,
    "closing_time": null
  },
  "tuesday": {
    "is_closed": false,
    "opening_time": "10:00",
    "closing_time": "18:00"
  }
}
```
