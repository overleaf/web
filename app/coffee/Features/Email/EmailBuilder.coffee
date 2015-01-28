_ = require('underscore')

PersonalEmailLayout = require("./Layouts/PersonalEmailLayout")
NotificationEmailLayout = require("./Layouts/NotificationEmailLayout")
settings = require("settings-sharelatex")

templates = {}

templates.welcome =	
	subject:  _.template "Welcome to DataJoy"
	layout: PersonalEmailLayout
	type:"lifecycle"
	compiledTemplate: _.template '''
<p>Hi <%= first_name %>,</p>

<p>Thanks for signing up to DataJoy! If you ever get lost, you can log in again <a href="<%= siteUrl %>/login">here</a> with the email address "<%= to %>".</p>

<p>DataJoy is a new project, and we really need your feedback. Feel free to reply to this email if you have any comments or suggestions. What problems do you have when you use Python and R? What do you like about DataJoy? What do you need to do that you can't? What could we improve?

<p>(If you've got 10 minutes sometime in the next week, I'd love to have a Skype with you to find out what you need from DataJoy. Just let me know a time when you're available. There'll be a free account in for anyone who helps us out!)

<p>If you're new to Python or R, or looking for some inspiration, then have a look at our <a href="<%= siteUrl %>/templates">Examples Gallery</a>.</p>

<p>
Regards, <br>
James <br>
DataJoy Co-founder
</p>
'''

templates.canceledSubscription = 
	subject:  _.template "DataJoy thoughts"
	layout: PersonalEmailLayout
	type:"lifecycle"
	compiledTemplate: _.template '''
<p>Hi <%= first_name %>,</p>

<p>I'm sorry to see you cancelled your DataJoy premium account. Would you mind giving me some advice on what the site is lacking at the moment? Feedback from our users is the only way we can improve DataJoy.</p>

<p>Thank you in advance.</p>

<p>
James <br>
DataJoy Co-founder
</p>
'''

templates.passwordResetRequested =	
	subject:  _.template "Password Reset - DataJoy"
	layout: NotificationEmailLayout
	type:"notification"
	compiledTemplate: _.template '''
<h1 class="h1">Password Reset</h1>
<p>
We got a request to reset your DataJoy password.
<p>
<center>
	<div style="width:200px;background-color:#a93629;border:1px solid #e24b3b;border-radius:3px;padding:15px; margin:12.5px;">
		<div style="padding-right:10px;padding-left:10px">
			<a href="<%= setNewPasswordUrl %>" style="text-decoration:none" target="_blank">
				<span style= "font-size:16px;font-family:Arial;font-weight:bold;color:#fff;white-space:nowrap;display:block; text-align:center">
		  			Reset password
				</span>
			</a>
		</div>
	</div>
</center>

If you ignore this message, your password won't be changed.
<p>
If you didn't request a password reset, let us know.

</p>
<p>Thank you</p>
<p> <a href="<%= siteUrl %>"> DataJoy </a></p>
'''

templates.projectSharedWithYou = 
	subject: _.template "<%= owner.email %> wants to share <%= project.name %> with you"
	layout: NotificationEmailLayout
	type:"notification"
	compiledTemplate: _.template '''
<p>Hi, <%= owner.email %> wants to share <a href="<%= project.url %>">'<%= project.name %>'</a> with you</p>
<p>&nbsp;</p>
<center>
	<div style="width:200px;background-color:#a93629;border:1px solid #e24b3b;border-radius:3px;padding:15px; margin:12.5px;">
		<div style="padding-right:10px;padding-left:10px">
			<a href="<%= project.url %>" style="text-decoration:none" target="_blank">
				<span style= "font-size:16px;font-family:Helvetica,Arial;font-weight:400;color:#fff;white-space:nowrap;display:block; text-align:center">
		  			View Project
				</span>
			</a>
		</div>
	</div>
</center>
<p> Thank you</p>
<p> <a href="<%= siteUrl %>"> DataJoy </a></p>

'''

module.exports =

	buildEmail: (templateName, opts)->
		template = templates[templateName]
		opts.siteUrl = settings.siteUrl
		opts.body = template.compiledTemplate(opts)
		return {
			subject : template.subject(opts)
			html: template.layout(opts)
			type:template.type
		}

