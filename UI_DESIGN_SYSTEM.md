# Season App - UI Design System & Features Documentation

## 📋 Table of Contents
1. [Color Palette](#color-palette)
2. [Typography](#typography)
3. [Spacing & Layout](#spacing--layout)
4. [UI Components](#ui-components)
5. [Features & UI Descriptions](#features--ui-descriptions)
6. [Design Principles](#design-principles)

---

## 🎨 Color Palette

### Primary Colors
| Color | Hex Code | Usage | Description |
|-------|----------|-------|-------------|
| **Primary** | `#092C4C` | Main brand color, buttons, headers | Deep navy blue - represents trust and professionalism |
| **Secondary** | `#E69146` | Accent color, highlights, CTAs | Warm orange - represents energy and warmth |

### Background Colors
| Color | Hex Code | Usage | Description |
|-------|----------|-------|-------------|
| **Background Light** | `#F8F9FA` | Light mode background | Soft gray background for light theme |
| **Background Dark** | `#121212` | Dark mode background | Deep black for dark theme |
| **Card Background** | `#FFFFFF` | Card containers | Pure white for cards and elevated surfaces |
| **Input Background** | `#F7F9FC` | Text field backgrounds | Light blue-gray for input fields |

### Text Colors
| Color | Hex Code | Usage | Description |
|-------|----------|-------|-------------|
| **Text Primary** | `#212121` | Main text content | Dark gray for primary text |
| **Text Secondary** | `#757575` | Secondary text, hints | Medium gray for secondary information |
| **Text Light** | `#FFFFFF` | Text on dark backgrounds | White for text on colored backgrounds |

### Status Colors
| Color | Hex Code | Usage | Description |
|-------|----------|-------|-------------|
| **Success** | `#4CAF50` | Success messages, confirmations | Green for positive actions |
| **Error** | `#CA2727` | Error messages, warnings | Red for errors and critical alerts |
| **Warning** | `#FFC107` | Warning messages | Amber for warnings |
| **Info** | `#2196F3` | Information messages | Blue for informational content |

### Border Colors
| Color | Hex Code | Usage | Description |
|-------|----------|-------|-------------|
| **Border** | `#E0E0E0` | Default borders | Light gray for borders |
| **Input Border** | `#E6ECF5` | Input field borders | Light blue-gray for input borders |
| **Input Focus Border** | `#6C8EF5` | Focused input borders | Blue for focused input states |

### Bag Feature Colors
| Color | Hex Code | Usage | Description |
|-------|----------|-------|-------------|
| **Bag Gradient Start** | `#092C4C` | Bag page gradients | Primary color for gradient start |
| **Bag Gradient End** | `#E69146` | Bag page gradients | Secondary color for gradient end |
| **Bag Tips Background** | `#EAF2F8` | Tips section background | Light blue for tips containers |
| **Bag Secondary Button BG** | `#FFF3E0` | Secondary button background | Light orange tint for secondary actions |

---

## 📝 Typography

### Font Family
- **Primary Font**: `Cairo`
  - Supports Arabic and English text
  - Modern, clean sans-serif design
  - Excellent readability in both languages

### Text Styles

#### Display Styles
| Style | Size | Weight | Color | Usage |
|-------|------|--------|-------|-------|
| **Display Large** | 32px | Bold | Black/White | Hero titles, main headings |
| **Display Medium** | 26px | Semi-Bold (600) | Black/White | Section titles |

#### Body Styles
| Style | Size | Weight | Color | Usage |
|-------|------|--------|-------|-------|
| **Body Large** | 16px | Medium (500) | Gray[800]/Gray[300] | Primary body text |
| **Body Medium** | 14px | Regular | Gray[700]/Gray[400] | Secondary body text |

#### Label Styles
| Style | Size | Weight | Color | Usage |
|-------|------|--------|-------|-------|
| **Label Large** | 14px | Bold | Primary | Button labels, form labels |

### App Bar Typography
- **Font Family**: Cairo
- **Size**: 20px
- **Weight**: Bold
- **Color**: Black (Light) / White (Dark)
- **Alignment**: Center

---

## 📐 Spacing & Layout

### Padding Values
| Size | Value | Usage |
|------|-------|-------|
| **Small** | 8px | Tight spacing, icon padding |
| **Medium** | 16px | Standard spacing, card padding |
| **Large** | 24px | Section spacing, large containers |

### Border Radius
| Size | Value | Usage |
|------|-------|-------|
| **Small** | 8px | Small buttons, badges |
| **Medium** | 12-14px | Cards, input fields, buttons |
| **Large** | 16-20px | Large cards, modals, bottom sheets |

### Spacing Between Elements
| Size | Value | Usage |
|------|-------|-------|
| **Small** | 8px | Related elements |
| **Medium** | 16px | Standard element spacing |
| **Large** | 32px | Section separation |

### Shadows
| Type | Properties | Usage |
|------|-----------|-------|
| **Card Shadow** | Color: `#33000000`, Blur: 6px, Offset: (0, 2) | Card elevation |
| **Button Shadow** | Color: Primary with 30% opacity, Blur: 20px, Offset: (0, 8) | Elevated buttons |
| **Toast Shadow** | Color: Background with 30% opacity, Blur: 20px, Offset: (0, 8) | Toast notifications |

---

## 🧩 UI Components

### Buttons

#### Primary Button (CustomButton)
- **Background**: Primary color (`#092C4C`) or custom color
- **Text Color**: White
- **Height**: 50px (default)
- **Border Radius**: 12px
- **Font**: Cairo, 16px, Bold
- **States**: 
  - Enabled: Full opacity
  - Disabled: Reduced opacity
  - Loading: Shows CircularProgressIndicator
- **Usage**: Main actions, CTAs, form submissions

#### Secondary Button
- **Background**: Transparent or light tint
- **Border**: 1px solid primary color
- **Text Color**: Primary color
- **Border Radius**: 12px
- **Usage**: Secondary actions, cancel buttons

#### Outlined Button
- **Background**: Transparent
- **Border**: 1px solid border color
- **Text Color**: Text primary
- **Border Radius**: 12px
- **Usage**: Tertiary actions, less important actions

### Text Fields (CustomTextField)

#### Default Style
- **Background**: `#F7F9FC` (light blue-gray)
- **Border**: 
  - Default: `#E6ECF5` (light blue-gray)
  - Focused: `#6C8EF5` (blue), 1.5px width
- **Border Radius**: 14px
- **Padding**: 16px horizontal, 14px vertical
- **Font**: Cairo
- **Text Direction**: Auto (RTL for Arabic, LTR for English)
- **Features**:
  - Optional country code picker
  - Prefix/suffix icons
  - Multi-line support
  - Custom validation

### Dropdown (CustomDropdown)

#### Style
- **Background**: `#F7F9FC`
- **Border**: 
  - Default: `#E6ECF5`
  - Focused: `#6C8EF5`, 1.5px width
- **Border Radius**: 14px
- **Dropdown Menu**: White background, max height 320px
- **Icon**: Arrow forward (iOS style), 16px
- **Font**: Cairo, 14px, Semi-Bold (600)

### Cards

#### Standard Card
- **Background**: White
- **Border Radius**: 12-20px
- **Shadow**: Card shadow (subtle elevation)
- **Padding**: 16-20px
- **Usage**: Content containers, information display

#### Info Card
- **Background**: White with gradient header
- **Header**: Primary color gradient
- **Content**: White background
- **Border Radius**: 20px (top corners rounded)
- **Usage**: Feature information, instructions

### Toast Notifications (CustomToast)

#### Style
- **Position**: Top of screen (below status bar)
- **Border Radius**: 16px
- **Padding**: 16px horizontal, 14px vertical
- **Animation**: Slide down + fade in (300ms)
- **Shadow**: Colored shadow matching toast type
- **Icon**: Circular background with white icon
- **Font**: Cairo, 14px, Semi-Bold (600), White
- **Types**:
  - Success: Green (`#4CAF50`)
  - Error: Red (`#CA2727`)
  - Warning: Amber (`#FFC107`)
  - Info: Blue (`#2196F3`)

### Bottom Navigation Bar (CustomNotchedBottomBar)

#### Style
- **Type**: Notched bottom bar with floating action button
- **Background**: White with shadow
- **Border Radius**: 16px
- **Notch**: 105px width, 47px depth for FAB
- **FAB**: 54px circle, primary color
- **Items**: 4 navigation items (Bag, Reminders, Groups, Profile)
- **Icons**: Material Icons
- **Labels**: Cairo font, responsive to language
- **RTL Support**: Items reversed for Arabic

---

## 🎯 Features & UI Descriptions

### 1. Home Page (الصفحة الرئيسية)

#### UI Description
- **Layout**: Scrollable content with sections
- **Header**: Gradient background with primary color
- **Sections**:
  - Welcome banner with user greeting
  - Loyalty points card (blue gradient)
  - Quick actions grid
  - Featured services
  - Vendor services preview
  - Digital directory shortcuts
  - Events section
- **Colors**: 
  - Primary gradient: `#092C4C` to `#E69146`
  - Cards: White with subtle shadows
- **Typography**: Cairo font, bold headings, medium body text
- **Spacing**: 16px between sections, 24px for major sections

#### Key Components
- Loyalty points banner with gradient background
- Service cards with icons and descriptions
- Action buttons with primary/secondary styling

---

### 2. Bag Management (إدارة الحقائب)

#### UI Description
- **Layout**: List view with bag cards
- **Bag Card Design**:
  - Gradient header (Primary to Secondary)
  - Bag type icon and title
  - Weight indicator with progress bar
  - Item count badge
  - Action buttons (View, Edit, Delete)
- **Colors**:
  - Card gradient: `#092C4C` → `#E69146`
  - Progress bar: Secondary color
  - Buttons: Primary and secondary colors
- **Typography**: 
  - Title: 20px, Bold, White
  - Subtitle: 14px, Medium, White with opacity
- **Spacing**: 16px between cards, 24px section padding

#### Bag Detail Screen
- **Header**: Bag image/icon with gradient overlay
- **Weight Display**: Large, prominent weight indicator
- **Items List**: Card-based item display
  - Item name, quantity, weight
  - Category icons
  - Essential item badges
- **Actions**: 
  - Add item button (Primary)
  - AI suggestions button (Secondary)
  - Edit/Delete options
- **Reminders Section**: 
  - Active reminders count
  - Reminder cards with date/time
  - Add reminder button

#### Bag Analysis Screen
- **Layout**: Scrollable analysis results
- **Sections**:
  - Missing items (suggestions to add)
  - Extra items (suggestions to remove)
  - Weight optimization tips
  - Additional suggestions
- **Card Style**: 
  - White background
  - Rounded corners (12px)
  - Subtle shadows
  - Icon + text layout
- **Action Buttons**:
  - "Add" button: Green accent
  - "Remove" button: Orange accent
  - "Apply All": Primary color, full width
- **Colors**:
  - Success: Green for add actions
  - Info: Orange for remove actions
  - Primary: Main CTA buttons

---

### 3. Reminders (التذكيرات)

#### UI Description
- **Layout**: List view with reminder cards
- **Reminder Card**:
  - Date/time header with color coding
  - Title and description
  - Recurrence indicator
  - Attachment preview (if available)
  - Action buttons (Edit, Delete)
- **Colors**:
  - Card background: White
  - Date header: Primary color gradient
  - Priority indicators: Color-coded (High: Red, Medium: Orange, Low: Green)
- **Empty State**:
  - Illustration or icon
  - Message: "No reminders yet"
  - CTA: "Add reminder" button
- **Add Reminder Modal**:
  - Form with date/time pickers
  - Recurrence selector
  - Notes field
  - Attachment picker
  - Save button (Primary)

---

### 4. Groups (المجموعات)

#### UI Description
- **Layout**: Grid/List view of group cards
- **Group Card**:
  - Group image/avatar
  - Group name and description
  - Member count badge
  - Status indicator (Active/Inactive)
  - Role badge (Owner/Member)
- **Colors**:
  - Card: White with shadow
  - Primary actions: Primary color
  - Member badge: Secondary color
- **Group Detail Screen**:
  - Header: Group image with gradient overlay
  - Member list with avatars
  - Map view integration
  - SOS alerts section
  - Settings (for owners)
- **Create/Join Group**:
  - Form with group name, description
  - QR scanner option
  - Invite code input
  - Safety radius settings

---

### 5. Profile (الملف الشخصي)

#### UI Description
- **Header Section**:
  - Gradient background (Primary color)
  - Profile image (circular, 96px)
  - User name (White, 22px, Bold)
  - Edit button (floating, secondary color)
  - Settings icon (top right)
  - Loyalty points card (white card with star icon)
- **Information Cards**:
  - White background
  - Icon + label + value layout
  - Rounded corners (12px)
  - Subtle shadows
- **Action Buttons**:
  - "Show Points Card" button (White, primary text)
  - Service provider buttons (Secondary and Primary)
- **Colors**:
  - Header: Primary gradient
  - Cards: White
  - Icons: Primary color with light background
  - Buttons: Primary and secondary colors

#### Edit Profile Screen
- **Avatar Section**:
  - Large circular avatar (120px)
  - Upload image button
  - Change photo button
- **Form Fields**:
  - Custom text fields with icons
  - Date picker for birth date
  - Gender dropdown
  - Country code picker for phone
- **Save Button**: Primary color, full width

---

### 6. Loyalty Points Card

#### UI Description
- **Display**: Bottom sheet modal
- **Card Design**:
  - Background image with gradient overlay
  - User name (White, 16px, Bold)
  - QR code (80x80px, white background)
  - Loyalty points display (White, 16px)
  - Points value (White, 16px, Bold)
- **Info Section**:
  - White card with rounded corners
  - Gradient header (Primary color)
  - Information items with icons
  - Tips and instructions
- **Colors**:
  - Card background: Image with dark gradient overlay
  - Text: White with shadows for readability
  - Info card: White with primary header

---

### 7. Vendor Services

#### UI Description
- **List View**: Grid of service cards
- **Service Card**:
  - Service image
  - Service name and type
  - Location badge
  - Status indicator
  - Action buttons
- **Form Screen**:
  - Multi-step form
  - Image picker for service photos
  - Map location picker
  - File upload for commercial register
  - Category selection
- **Colors**:
  - Primary actions: Primary color
  - Secondary actions: Secondary color
  - Status badges: Color-coded

---

### 8. Geographical Guides

#### UI Description
- **Directory View**: 
  - Category filters
  - Service cards with location
  - Map integration
- **Service Card**:
  - Service name and category
  - Location with distance
  - Contact information
  - Rating/reviews (if available)
- **Apply as Trader Form**:
  - Comprehensive form with multiple fields
  - Location picker with map
  - Commercial register upload
  - Category and sub-category selection

---

### 9. Emergency Contacts

#### UI Description
- **Layout**: Grid of emergency service cards
- **Service Card**:
  - Icon (Fire, Police, Ambulance, Embassy)
  - Service name
  - Phone number (tappable)
  - Quick call button
- **Colors**:
  - Fire: Red accent
  - Police: Blue accent
  - Ambulance: Red accent
  - Embassy: Primary color
- **Card Style**: 
  - White background
  - Rounded corners (16px)
  - Icon with colored background
  - Shadow for elevation

---

### 10. Currency Converter

#### UI Description
- **Layout**: Form-based converter
- **Input Fields**:
  - From currency selector
  - To currency selector
  - Amount input
- **Display**:
  - Exchange rate
  - Converted amount (large, prominent)
  - Last updated timestamp
- **Colors**:
  - Primary button: Primary color
  - Input fields: Standard input styling
  - Result display: Primary color text

---

## 🎨 Design Principles

### 1. Consistency
- **Color Usage**: Primary color for main actions, secondary for accents
- **Typography**: Cairo font throughout the app
- **Spacing**: Consistent 8px, 16px, 24px spacing system
- **Border Radius**: 12-14px for most components

### 2. Accessibility
- **Contrast**: High contrast ratios for text readability
- **Touch Targets**: Minimum 44x44px for interactive elements
- **Font Sizes**: Minimum 14px for body text
- **RTL Support**: Full right-to-left support for Arabic

### 3. Visual Hierarchy
- **Primary Actions**: Bold, primary color, prominent placement
- **Secondary Actions**: Outlined, less prominent
- **Information**: Subtle colors, smaller text
- **Status Indicators**: Color-coded for quick recognition

### 4. Modern Design
- **Material Design 3**: Using Material 3 components
- **Gradients**: Subtle gradients for depth
- **Shadows**: Soft shadows for elevation
- **Rounded Corners**: Modern, friendly appearance
- **Smooth Animations**: 300ms transitions for interactions

### 5. Responsive Design
- **Flexible Layouts**: Adapts to different screen sizes
- **Safe Areas**: Respects device safe areas
- **Scalable Text**: Responsive font sizing
- **Adaptive Components**: Components adjust to content

---

## 📱 Screen-Specific UI Patterns

### Header Patterns

#### Gradient Header (Profile, Bag Details)
- **Background**: Primary color gradient
- **Content**: White text
- **Height**: Variable (typically 200-250px)
- **Elements**: 
  - Title/Name (Large, Bold)
  - Avatar/Image (Circular)
  - Action buttons (White with opacity)

#### Standard Header (AppBar)
- **Background**: White (Light) / Dark (Dark mode)
- **Title**: Center-aligned, Bold, 20px
- **Actions**: Icon buttons on sides
- **Elevation**: 0 (flat design)

### Card Patterns

#### Information Card
- **Layout**: Icon + Title + Value
- **Background**: White
- **Border**: None (shadow for separation)
- **Padding**: 12-16px
- **Border Radius**: 12px

#### Action Card
- **Layout**: Image/Icon + Title + Description + Actions
- **Background**: White
- **Shadow**: Subtle elevation
- **Actions**: Primary/secondary buttons
- **Border Radius**: 12-20px

### Form Patterns

#### Standard Form
- **Layout**: Vertical stack of fields
- **Spacing**: 16px between fields
- **Validation**: Real-time with error messages
- **Submit Button**: Full width, primary color, bottom of form

#### Multi-Step Form
- **Progress Indicator**: Top of screen
- **Step Navigation**: Previous/Next buttons
- **Validation**: Per-step validation
- **Final Step**: Submit button

### Empty States

#### Pattern
- **Icon/Illustration**: Large, centered
- **Title**: Bold, 18-20px
- **Description**: Medium, 14-16px, secondary color
- **CTA Button**: Primary color, centered
- **Spacing**: Generous padding (24-32px)

### Loading States

#### Pattern
- **Indicator**: CircularProgressIndicator
- **Color**: Primary color
- **Size**: 22-24px for buttons, 40-48px for screens
- **Background**: Overlay for full-screen loading
- **Message**: Optional text below indicator

---

## 🌐 Internationalization (i18n)

### Language Support
- **Primary**: Arabic (RTL)
- **Secondary**: English (LTR)
- **Default**: Arabic

### RTL Considerations
- **Layout**: Automatic mirroring for RTL
- **Icons**: Directional icons flip automatically
- **Text Alignment**: Right-aligned for Arabic, left for English
- **Navigation**: Bottom nav items reversed for RTL

---

## 🎭 Theme Support

### Light Theme
- **Background**: `#F8F9FA`
- **Cards**: White
- **Text**: Dark gray/black
- **Primary**: `#092C4C`
- **Secondary**: `#E69146`

### Dark Theme
- **Background**: `#121212`
- **Cards**: Dark gray
- **Text**: White/light gray
- **Primary**: `#092C4C` (maintained)
- **Secondary**: `#E69146` (maintained)

---

## 📊 Component Specifications

### Button Specifications
```
Height: 50px (default)
Border Radius: 12px
Padding: 16px horizontal (auto)
Font: Cairo, 16px, Bold
Minimum Width: 120px
Touch Target: 44x44px minimum
```

### Input Field Specifications
```
Height: 48px (default)
Border Radius: 14px
Padding: 16px horizontal, 14px vertical
Font: Cairo, 14-16px
Background: #F7F9FC
Border: 1px solid #E6ECF5
Focus Border: 1.5px solid #6C8EF5
```

### Card Specifications
```
Border Radius: 12-20px
Padding: 16-20px
Shadow: Subtle (blur 6-10px, offset 0,2)
Background: White
Minimum Height: 80px
```

### Avatar Specifications
```
Size: 48px (small), 60px (medium), 96px (large), 120px (xlarge)
Shape: Circle
Border: 2-3px white border
Shadow: Subtle shadow for depth
```

---

## 🎯 Feature-Specific UI Details

### Bag Analysis Feature
- **Color Coding**:
  - Missing items: Green accent
  - Extra items: Orange accent
  - Suggestions: Blue accent
- **Card Layout**: Icon + Title + Description + Action button
- **Bottom Actions**: Fixed bottom bar with "Apply All" and "Return" buttons

### Group Tracking Feature
- **Map Integration**: Google Maps with custom markers
- **Member Avatars**: Small circular avatars in list
- **Status Indicators**: Color-coded (Active: Green, Inactive: Gray)
- **SOS Alerts**: Red accent, prominent display

### Reminders Feature
- **Date Display**: Large, prominent date header
- **Time Display**: 24-hour format with AM/PM indicator
- **Recurrence Badge**: Small badge showing recurrence pattern
- **Priority Indicator**: Color-coded border or icon

---

## 📐 Layout Guidelines

### Screen Padding
- **Standard**: 16px horizontal
- **Large Screens**: 24px horizontal
- **Section Spacing**: 24-32px vertical

### Grid System
- **Columns**: Flexible (no fixed grid)
- **Card Width**: Full width with 16px padding
- **Card Spacing**: 12-16px between cards

### Content Width
- **Maximum**: No fixed max (responsive)
- **Optimal Reading**: 600-800px equivalent
- **Padding**: 16-24px from screen edges

---

## 🎨 Animation Guidelines

### Transition Durations
- **Fast**: 150ms (micro-interactions)
- **Standard**: 300ms (most transitions)
- **Slow**: 500ms (complex animations)

### Easing Curves
- **Standard**: `Curves.easeOutCubic`
- **Bounce**: `Curves.easeOutBack` (for playful elements)
- **Linear**: `Curves.linear` (for progress indicators)

### Common Animations
- **Page Transitions**: Slide + fade (300ms)
- **Modal Open**: Scale + fade (300ms)
- **Toast**: Slide down + fade (300ms)
- **Button Press**: Scale down (100ms)

---

## 📱 Platform-Specific Considerations

### Android
- **Material Design 3**: Full Material 3 implementation
- **Navigation**: Bottom navigation with notched FAB
- **Back Button**: Standard Android back navigation

### iOS
- **Cupertino Elements**: Where appropriate
- **Navigation**: Stack-based navigation
- **Gestures**: Swipe gestures supported

---

## 🔧 Customization Guidelines

### Color Customization
- All colors defined in `AppColors` class
- Easy to modify for rebranding
- Consistent usage throughout app

### Typography Customization
- Font family: Cairo (can be changed in theme)
- Sizes: Defined in `AppTextStyles`
- Weights: Standard Material weights

### Component Customization
- All components in `shared/widgets`
- Reusable across the app
- Consistent styling enforced

---

## 📝 Notes for Developers

1. **Always use AppColors**: Never hardcode colors
2. **Use Custom Components**: Use shared widgets for consistency
3. **Follow Spacing System**: Use AppValues for spacing
4. **RTL Support**: Test in both Arabic and English
5. **Dark Mode**: Ensure all screens support dark theme
6. **Accessibility**: Maintain minimum touch targets and contrast ratios

---

## 🎨 Visual Examples

### Color Palette Visualization
```
Primary:   ████████ #092C4C (Deep Navy)
Secondary: ████████ #E69146 (Warm Orange)
Success:   ████████ #4CAF50 (Green)
Error:     ████████ #CA2727 (Red)
Warning:   ████████ #FFC107 (Amber)
Info:      ████████ #2196F3 (Blue)
```

### Typography Scale
```
Display Large:  32px Bold    (Hero Titles)
Display Medium: 26px Semi    (Section Titles)
Body Large:     16px Medium  (Primary Text)
Body Medium:    14px Regular (Secondary Text)
Label Large:    14px Bold    (Buttons, Labels)
```

---

*Last Updated: 2024*
*Version: 1.0.0*

