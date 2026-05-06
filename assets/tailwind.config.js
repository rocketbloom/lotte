/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './js/**/*.js',
    '../lib/lotte_web.ex',
    '../lib/lotte_web/**/*.*ex'
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#faf7f9',
          100: '#f5eff4',
          200: '#eaddec',
          300: '#dfc6e2',
          400: '#cf9ecb',
          500: '#a81d69',
          600: '#9a1a60',
          700: '#7f1551',
          800: '#641042',
          900: '#4a0d32',
        },
        secondary: {
          50: '#f0f6f7',
          100: '#e0eeef',
          200: '#c1dddf',
          300: '#9cc5ca',
          400: '#6fa5b2',
          500: '#1f4a54',
          600: '#1c424c',
          700: '#163640',
          800: '#122a34',
          900: '#0d1e28',
        },
        accent: '#d99211',
        'accent-light': '#cda3ba',
        'neutral': '#aab6ba',
      },
      fontFamily: {
        sans: ['Poppins', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [require('daisyui')],
  daisyui: {
    themes: [
      {
        light: {
          'primary': '#a81d69',
          'secondary': '#1f4a54',
          'accent': '#d99211',
          'neutral': '#aab6ba',
          'base-100': '#ffffff',
        },
      },
    ],
  },
}
