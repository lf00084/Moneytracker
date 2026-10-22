import { Field, Google, Logo } from "../ui/primitives.tsx"
import { AuthPage } from "../ui/layout.tsx"
const AuthForm = ({ up, error }: { up: boolean; error: string }) => (
<div class="auth-center-wrap"><div class="auth-glass-box"><div class="auth-logo-center"><Logo href="/login" /></div><h1 class="auth-title">{up ? "Create account" : "Sign in"}</h1><div class="auth-sub">{up ? "Track what you spend and earn, day by day. Start in seconds." : "Track what you spend and earn, day by day."}</div><form class="au" method="post" action={up ? "/signup" : "/login"}><a class="gbtn" href="/login/google"><Google /><span>{up ? "Sign up with Google" : "Continue with Google"}</span></a><div class="or">or</div>{error ? <div class="auth-err-banner" role="alert">{error}</div> : null}{up ? <Field label="Name" name="name" placeholder="Your name" /> : null}<Field label="Email" type="email" name="email" placeholder="you@email.com" /><Field label="Password" type="password" name="password" placeholder="••••••••" /><button class="btn full">{up ? "Create account" : "Sign in"}</button><div class="auth-switch-wrap"><a class="lnk-switch" href={up ? "/login" : "/signup"}>{up ? <>Already have an account? <b>Sign in</b></> : <>Don't have an account? <b>Create account</b></>}</a></div></form></div></div>
)
export const LoginScreen = ({ error = "" }: { error?: string }) => (
<AuthPage title="Sign in" path="/login" desc="Sign in to Moneytracker, your quiet personal money tracker."><AuthForm up={false} error={error} /></AuthPage>
)
export const SignupScreen = ({ error = "" }: { error?: string }) => (
<AuthPage title="Create account" path="/signup" desc="Create a free Moneytracker account and start tracking your spending, debts and goals."><AuthForm up={true} error={error} /></AuthPage>
)
