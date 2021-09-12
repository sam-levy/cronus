module.exports = {
  mode: "jit",
  purge: ["./js/**/*.js", "../lib/*_live/**/*.*ex"],
  theme: {
    extend: {},
  },
  variants: {
    extend: {},
  },
  plugins: [require('@tailwindcss/forms')],
};