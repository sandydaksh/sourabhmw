module MemberNotifyHelper
  def login_button(url)
    %{<tr>
      <td style="padding-bottom: 20px;"> 
        <center>
          <a href="#{url}" style="border: 0;"><img src="http://meetingwave.com/images/ttb/login.png" alt="Login" border="0" /></a>
        </center>
      </td> 
    </tr> 
    #{in_case_of_link_stripping(url)}
    }
  end

  def change_password_button(url)
    %{<tr>
      <td style="padding-bottom: 20px;"> 
        <center>
          <a href="#{url}" style="border: 0;"><img src="http://meetingwave.com/images/meetingwave/buttons/change_password.gif" alt="Change Password" border="0" /></a>
        </center>
      </td> 
    </tr>
    #{in_case_of_link_stripping(url)}
     }
  end

  WARNING_STYLE = "margin-top: 10px; font-size: 0.75em;"
  def warning_msg(warning)
      %{<tr>
        <td style="font: 1.0em arial; color: #42412d; padding: 25px;">
          <p style="#{WARNING_STYLE}">#{warning}</p>
        </td>
      </tr> }
  end

  def warning_msg_txt(warning)
      word_wrap("NOTE: #{warning}")
  end

end
