# Banner Routes - No ID Required

This document lists all screen routes that **do NOT require an ID parameter**. These routes can be used when a user clicks on a banner to navigate to a specific screen.

## Authentication Routes
| Route | Path | Description |
|-------|------|-------------|
| Login | `/login` | User login screen |
| Sign Up | `/signUp` | User registration screen |
| Welcome | `/welcome` | Welcome/onboarding screen |
| Verify OTP | `/verifyOtp` | OTP verification screen |
| Forgot Password | `/forgotPassword` | Forgot password screen |
| Verify Reset OTP | `/verifyResetOtp` | Verify OTP for password reset |
| Reset Password | `/resetPassword` | Reset password screen |

## Main App Routes
| Route | Path | Description |
|-------|------|-------------|
| Home | `/home` | Main home screen (tab navigation) |
| Bag Page | `/home?tab=bag` | Opens bag page (الحقيبة) |
| Reminders Page | `/home?tab=reminders` | Opens reminders page (التذكيرات) |
| Groups Page (Tab) | `/home?tab=groups` | Opens groups page tab (المجموعات) |
| Profile | `/profile` | User profile screen |
| Profile Edit | `/profile/edit` | Edit user profile screen |
| Settings | `/settings` | App settings screen |
| Splash | `/` | Splash/loading screen |

## Vendor Services Routes
| Route | Path | Description |
|-------|------|-------------|
| My Vendor Services | `/vendor/services` | List of user's vendor services |
| New Vendor Service | `/vendor/services/new` | Create new vendor service form |
| Public Vendor Services | `/vendor/services/public` | Public listing of all vendor services |

## Geographical Guides Routes
| Route | Path | Description |
|-------|------|-------------|
| Geographical Directory | `/geographical-directory` | Public directory of geographical guides |
| Apply as Trader | `/apply-as-trader` | Apply as geographical guide trader (redirects to My Services) |
| My Geographical Services | `/my-geographical-services` | User's geographical guide services list |
| New Geographical Guide | `/geographical-guides/new` | Create new geographical guide form |

## Digital Directory Routes
| Route | Path | Description |
|-------|------|-------------|
| Categories | `/categories` | List of app categories |

## Utility Routes
| Route | Path | Description |
|-------|------|-------------|
| Emergency | `/emergency` | Emergency contacts screen |
| Currency Converter | `/currency/converter` | Currency conversion tool |
| Location Picker | `/location/picker` | Map-based location picker (accepts query params: `lat`, `lng`) |
| WebView | `/webview` | Generic webview screen (accepts query params: `url`, `title`) |

## Groups Routes
| Route | Path | Description |
|-------|------|-------------|
| Groups List | `/groups` | List of user's groups |
| Create Group | `/groups/create` | Create new group screen |
| Join Group | `/groups/join` | Join a group screen |
| QR Scanner | `/groups/qr-scanner` | QR code scanner for groups |

---

## Notes for Backend Developer

1. **Query Parameters**: Some routes accept optional query parameters:
   - `/webview?url=<URL>&title=<TITLE>` - Opens a webview with the specified URL and title
   - `/location/picker?lat=<LATITUDE>&lng=<LONGITUDE>` - Opens location picker at specified coordinates
   - `/home?tab=<TAB>` - Opens home screen with specific tab selected. Valid values: `bag`, `reminders`, `groups`, `profile`

2. **Route Format**: All routes are absolute paths starting with `/`

3. **Banner Integration**: When a user clicks a banner, you can send one of these route paths to navigate the user to the corresponding screen.

4. **Routes with ID**: The following routes require an ID and are NOT included in this list:
   - `/vendor/services/:id` - Vendor service details
   - `/vendor/services/:id/edit` - Edit vendor service
   - `/vendor/services/public/:id` - Public vendor service details
   - `/categories/:id/apps` - Category apps list
   - `/geographical-guides/:id` - Geographical guide details
   - `/geographical-guides/:id/edit` - Edit geographical guide
   - `/my-geographical-services/:id` - My geographical service details
   - `/groups/:id` - Group details
   - `/groups/:id/edit` - Edit group
   - `/groups/:id/sos` - Group SOS alerts

---

## Example Banner Payload Structure

```json
{
  "banner_id": 1,
  "title": "Check out our services",
  "image_url": "https://example.com/banner.jpg",
  "route": "/geographical-directory",
  "route_type": "internal"
}
```

Or with query parameters:

```json
{
  "banner_id": 2,
  "title": "Visit our website",
  "image_url": "https://example.com/banner2.jpg",
  "route": "/webview",
  "route_params": {
    "url": "https://example.com",
    "title": "Our Website"
  },
  "route_type": "internal"
}
```

Example for opening bag page:

```json
{
  "banner_id": 3,
  "title": "View your bags",
  "image_url": "https://example.com/banner3.jpg",
  "route": "/home",
  "route_params": {
    "tab": "bag"
  },
  "route_type": "internal"
}
```


